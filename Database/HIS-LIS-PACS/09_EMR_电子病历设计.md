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
| content | TEXT | 结构化 JSON 内容 |
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
| doc_type | VARCHAR(30) | 适用病历类型 |
| content_template | TEXT | 结构化 JSON 模板 |
| department_id | BIGINT | 所属科室（null=全院） |
| is_public | BOOLEAN | 是否公开 |

## 三级质控状态机

```
DRAFT ──提交──► PENDING_L1 ──通过──► PENDING_L2 ──通过──► PENDING_L3 ──通过──► APPROVED ──存档──► ARCHIVED
  ▲              │退回               │退回               │退回
  └──────────────┴───────────────────┴───────────────────┘
```

## API 清单

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/emr/documents | 创建病历 |
| PUT | /api/emr/documents/{id} | 更新内容 |
| GET | /api/emr/documents/{id} | 查详情 |
| GET | /api/emr/documents | 列表搜索 |
| POST | /api/emr/documents/{id}/submit | 提交审签 |
| POST | /api/emr/documents/{id}/review | 审核通过/退回 |
| GET | /api/emr/documents/{id}/audit | 审签流水 |
| POST | /api/emr/documents/{id}/archive | 归档 |
| GET | /api/emr/templates | 获取模板 |

## JSONB 结构化内容示例（入院记录）

```json
{
  "chiefComplaint": "主诉",
  "presentIllness": "现病史",
  "pastHistory": "既往史",
  "allergyHistory": "过敏史",
  "physicalExamination": {
    "temperature": "36.5℃",
    "pulse": "72次/分",
    "bloodPressure": "120/80mmHg"
  },
  "preliminaryDiagnosis": [
    {"code": "I10.x01", "name": "高血压", "isPrimary": true}
  ],
  "treatmentPlan": "诊疗计划"
}
```

## 预置模板（3 个）

| 模板名 | doc_type | 用途 |
|--------|----------|------|
| 门诊病历模板 | OUTPATIENT_RECORD | 门诊就诊记录 |
| 入院记录模板 | ADMISSION_RECORD | 住院登记后 |
| 日常病程记录模板 | PROGRESS_NOTE | 住院期间每日记录 |

---

*相关文档: [[05_HIS_实际数据库表]] [[07_HIS_业务流程]] [[08_HIS_数据流程]]*
*标签: #EMR #电子病历 #数据库 #API*
