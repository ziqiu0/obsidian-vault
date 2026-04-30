---
created: 2026-04-29
tags: #EMR, #电子病历, #数据库设计
---

# EMR 电子病历模块设计

> 基于项目代码中实际的 JPA Entity 和 API 设计
> 项目路径: `~/projects/his-lis-pacs/`

## 数据模型

### emr_document（病历主表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | PK |
| document_no | VARCHAR(50) | 病历编号（OP/ADM/PRO + 日期 + 序号） |
| patient_id | BIGINT | 患者ID |
| patient_name | VARCHAR(100) | 患者姓名 |
| visit_type | VARCHAR(20) | OUTPATIENT / INPATIENT |
| visit_id | BIGINT | 关联 registration 或 inpatient_admissions |
| department_id / department_name | | 科室冗余 |
| doctor_id / doctor_name | | 经治医生 |
| doc_type | VARCHAR(30) | OUTPATIENT_RECORD / ADMISSION_RECORD / PROGRESS_NOTE |
| title | VARCHAR(200) | 病历标题 |
| content | TEXT | HTML 富文本内容 |
| status | VARCHAR(20) | 状态机 |
| version | INT | 版本号 |
| is_latest | BOOLEAN | 是否当前版本 |
| archived_at | TIMESTAMP | 归档时间 |

### emr_audit_trail（审签流水表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | PK |
| document_id | BIGINT | FK→emr_document |
| reviewer_id / reviewer_name | | 审核人 |
| review_level | INT | 1/2/3 级审签 |
| action | VARCHAR(20) | SUBMIT / PASS / REJECT |
| comment | TEXT | 审核意见 |

### emr_template（病历模板表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | PK |
| name | VARCHAR(100) | 模板名称 |
| doc_type | VARCHAR(30) | 适用病历类型（用于自动匹配） |
| content_template | TEXT | HTML 模板内容 |
| department_id | BIGINT | 所属科室（null=全院） |
| is_public | BOOLEAN | 是否公开 |

## 三级质控状态机

```
DRAFT ──提交──► PENDING_L1 ──通过──► PENDING_L2 ──通过──► PENDING_L3 ──通过──► APPROVED ──存档──► ARCHIVED
  ▲              │退回               │退回               │退回
  └──────────────┴───────────────────┴───────────────────┘
```

## 操作按钮可见性

| 状态 | 按钮 |
|------|------|
| DRAFT | **编辑** + 提交 |
| PENDING_L1/L2/L3 | **查看** + 审核 |
| APPROVED | **查看** + 归档 |
| ARCHIVED | **查看** |

- **编辑模式**: WangEditor 富文本编辑器可编辑，有保存按钮、模板选择条
- **查看模式**: WangEditor 只读渲染（editor.disable()），无保存按钮、无模板条

## API 清单

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/emr/documents | 创建病历（默认 content="{}"） |
| PUT | /api/emr/documents/{id} | 更新内容（校验 status==DRAFT） |
| GET | /api/emr/documents/{id} | 查详情 |
| GET | /api/emr/documents | 列表搜索（分页 + 多条件） |
| POST | /api/emr/documents/{id}/submit | 提交审签 |
| POST | /api/emr/documents/{id}/review | 审核通过/退回 |
| GET | /api/emr/documents/{id}/audit | 审签流水 |
| POST | /api/emr/documents/{id}/archive | 归档 |
| GET | /api/emr/templates | 获取模板（按 docType + departmentId 过滤） |

## 前端组件

### WangEditor.vue（通用富文本编辑器组件）

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| modelValue | String | '' | v-model 绑定 HTML 内容 |
| height | String | '500px' | 编辑器高度 |
| placeholder | String | '请输入内容...' | 占位文本 |
| readonly | Boolean | false | 只读模式（调用 editor.disable()） |

**工具栏排除项**: insertVideo, insertTable, codeBlock, blockquote, headerSelect, fullScreen, group-image, emotion, insertLink, insertImage, todo

**CSS 强制左对齐**: 编辑器内所有 p, div, h1-h6, span, section 均 `text-align: left !important`

### EmrManagement.vue（病历管理页面）

**模板选择逻辑**:
1. 进入编辑 → 调用 `GET /api/emr/templates?docType=<病历类型>`（后端按 docType 过滤）
2. 缓存返回的模板内容到 `templateContentCache`
3. 自动选中匹配 `docType` 的第一个模板（仅**空文档**时自动应用内容）
4. 用户可手动切换模板 radio-button 组
5. 切换时剥离 HTML 中的 `text-align` 内联样式 → 强制左对齐

**保存流程**:
```
用户编辑 → 点击保存 → PUT /api/emr/documents/{id} {content: "..."}
  → 后端校验 status==DRAFT → 更新 content → 返回200
  → 前端提示"保存成功" → 关闭弹窗 → 刷新列表
```

**错误处理**: 前端弹窗显示后端返回的 `response.data.message`（替代通用"保存失败"）

## 保存接口校验规则

```
updateContent(Long id, String content):
  1. documentRepository.findById(id)  → 不存在抛"病历不存在: {id}"
  2. status != "DRAFT"                → 抛"当前状态不允许修改，只有草稿可编辑"
  3. doc.setContent(content)          → documentRepository.save(doc)
```

## 自动化测试

**文件**: `backend/src/test/java/com/his/his/service/impl/EmrDocumentServiceTest.java`
**数据库**: H2 内存库（MODE=PostgreSQL），`application-test.properties`
**依赖**: spring-boot-starter-test + h2（test scope）

| 测试用例 | 场景 | 验证点 |
|---------|------|--------|
| 正常保存HTML内容 | DRAFT文档写入HTML | content 一致，status 不变 |
| 长文本内容 | 5000*"测试"的HTML | >10000字符正常存储 |
| 非草稿状态禁止编辑 | status=PENDING_L1 | 抛出"不允许修改" |
| 不存在的病历ID | id=99999 | 抛出"病历不存在" |
| 空内容 | content="" | 可存空字符串 |
| 仅HTML标签内容 | content="<p><br></p>" | 富文本编辑器空白正常保存 |
| 多次保存更新 | 保存两次 | 第二次覆盖第一次 |
| 审签退回后重新编辑 | DRAFT→退回→DRAFT | 退回后可再次编辑 |

## 模板与病历类型映射

| 病历类型 (docType) | 模板 | 自动匹配 |
|---------------------|------|:--------:|
| OUTPATIENT_RECORD | 门诊病历模板 | ✅（匹配同名） |
| ADMISSION_RECORD | 入院记录模板 | ✅（匹配同名） |
| PROGRESS_NOTE | 日常病程记录模板 | ✅（匹配同名） |

模板通过 `GET /api/emr/templates?docType=` 后端过滤，前端只展示匹配当前病历类型的模板。

## HTML 内容示例（入院记录）

```html
<p>主诉：头痛3天</p>
<p>现病史：患者3天前无明显诱因出现头痛...</p>
<p>既往史：高血压病史5年</p>
```

内容存储为 wangEditor 产出的完整 HTML 格式（非 JSONB），通过富文本编辑器编辑和渲染。

## 预置模板

| 模板名 | doc_type | 用途 |
|--------|----------|------|
| 门诊病历模板 | OUTPATIENT_RECORD | 门诊就诊记录 |
| 入院记录模板 | ADMISSION_RECORD | 住院登记后 |
| 日常病程记录模板 | PROGRESS_NOTE | 住院期间每日记录 |

---

*相关文档: [[05_HIS_实际数据库表]] [[07_HIS_业务流程]] [[08_HIS_数据流程]] [[06_HIS_UI页面与路由]]*
*标签: #EMR #电子病历 #数据库 #API #wangEditor*
