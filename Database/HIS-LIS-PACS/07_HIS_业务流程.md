---
created: 2026-04-29
tags: #HIS, #业务流程, #BPMN
---

# HIS 业务流程

> 医院信息系统核心业务流程梳理
> 涵盖门诊、住院、检验、影像、收费五大业务线

## 一、门诊就诊流程（核心主流程）

```mermaid
flowchart TD
    A[患者到达] --> B[挂号登记]
    B -->|选择科室+医生| C[生成挂号单]
    C -->|分配当日序号| D[候诊]
    D --> E[医生接诊]
    E --> F{诊断}
    F -->|开检验单| G[检验流程]
    F -->|开影像检查| H[影像流程]
    F -->|开处方| I[收费流程]
    F -->|需住院| J[住院流程]
    F -->|无需处置| K[门诊结束]

    G --> L[标本采集]
    L --> M[检验执行]
    M --> N[检验报告]
    N --> E

    H --> O[影像检查]
    O --> P[影像报告]
    P --> E

    I --> Q[收费结算]
    Q --> R[发药]
    R --> K

    J --> S[住院登记]

    style A fill:#165DFF,color:#fff
    style K fill:#00B42A,color:#fff
    style S fill:#FF7D00,color:#fff
```

### 挂号四步流程（已实现）

```mermaid
flowchart LR
    S1[1. 选择患者] --> S2[2. 选择科室]
    S2 --> S3[3. 选择医生]
    S3 --> S4[4. 确认支付]

    style S1 fill:#E8F3FF
    style S2 fill:#E8F3FF
    style S3 fill:#E8F3FF
    style S4 fill:#E8F3FF
```

**挂号状态机:**
```mermaid
stateDiagram-v2
    [*] --> REGISTERED: 创建挂号
    REGISTERED --> VISITED: 医生接诊
    REGISTERED --> CANCELLED: 患者取消
    VISITED --> REFUNDED: 退费
    VISITED --> [*]: 就诊完成
    CANCELLED --> [*]
    REFUNDED --> [*]
```

**实现细节:**
- 挂号时自动从 Patient 表填充患者快照（姓名、性别、身份证、过敏史等 16 个字段）
- 科室/医生信息同步快照到挂号单
- 当日序号自增（visit_sequence）
- 前端: `his/RegistrationManagement.vue` → `api/registration.js`
- 后端: `RegistrationController` → `RegistrationService` → `Registration` Entity

---

## 二、住院流程

```mermaid
flowchart TD
    A[门诊/急诊医生] -->|开具住院证| B[住院登记]
    B -->|选择科室+病房+床位| C[分配床位]
    C --> D[住院治疗]
    D --> E{治疗方案}
    E -->|日常治疗| F[医嘱执行]
    E -->|转科| G[转科处理]
    E -->|出院| H[出院办理]
    G -->|释放原床位| C

    F --> I[护理记录]
    I --> D

    H --> J[费用结算]
    J --> K[归档病历]
    K --> L[释放床位]

    style B fill:#165DFF,color:#fff
    style H fill:#00B42A,color:#fff
    style L fill:#FF7D00,color:#fff
```

**住院登记字段:**
- 住院号（自动生成）
- 患者ID + 姓名
- 科室 + 病房 + 床位
- 主治医生
- 入院日期
- 主诉 + 诊断
- 状态: ADMITTED / DISCHARGED / TRANSFERRED

**实现:**
- 前端: `inpatient/AdmissionManagement.vue` → `api/inpatient.js`
- 后端: `AdmissionController` → `AdmissionService` → `Admission` Entity

---

## 三、检验流程 (LIS)

```mermaid
flowchart TD
    A[医生开检验医嘱] --> B[生成检验申请]
    B --> C[标本采集]
    C --> D[标本接收/核收]
    D --> E[上机检验]
    E --> F[结果录入]
    F --> G{质控}
    G -->|通过| H[报告审核]
    G -->|不通过| I[重新检验]
    I --> E
    H --> J[报告发布]
    J --> K[结果回传HIS]

    style A fill:#165DFF,color:#fff
    style J fill:#00B42A,color:#fff
    style K fill:#FF7D00,color:#fff
```

**前端页面（4 页已实现 UI）:**
| 页面 | 功能 |
|------|------|
| 检验工作列表 | 待检/在检/已完成任务管理 |
| 样本管理 | 样本接收、核收、查询 |
| 检验项目 | 检验项目/套餐字典管理 |
| 检验报告 | 报告查看、审核、打印 |

**后端已实现（2026-04-30）:**
- Entity: LisTestItem / LisTestRequest / LisTestRequestItem / LisSample / LisTestResult / LisReport
- Controller: TestItemController / TestRequestController / SampleController / (5 Controllers 总计)
- API: `api/lis.js`（全部4页对接完毕）

---

## 四、影像流程 (PACS)

```mermaid
flowchart TD
    A[医生开影像医嘱] --> B[影像登记]
    B --> C[患者排队]
    C --> D[设备检查]
    D --> E[图像采集]
    E --> F[DICOM存储]
    F --> G[阅片诊断]
    G --> H[书写报告]
    H --> I{报告审核}
    I -->|通过| J[报告发布]
    I -->|退回| H
    J --> K[结果回传HIS]

    style A fill:#165DFF,color:#fff
    style J fill:#00B42A,color:#fff
    style K fill:#FF7D00,color:#fff
```

**影像检查状态机:**
```mermaid
stateDiagram-v2
    [*] --> 待检查: 创建检查单
    待检查 --> 检查中: 开始检查
    检查中 --> 已完成: 图像采集完成
    已完成 --> 已阅片: 医生阅片
    已阅片 --> [*]
```

**实现:**
- 后端 Entity: `ImageStudy` → `pacs_image_study` 表
- 状态: 0-待检查, 1-检查中, 2-已完成, 3-已阅片
- 前端: `pacs/ImageManagement.vue` ✅, `pacs/ImageDiagnosis.vue` ❌ 待实现

---

## 五、收费流程

```mermaid
flowchart TD
    A[医嘱/处方/检查] --> B[费用生成]
    B --> C[收费结算]
    C --> D{支付方式}
    D -->|现金| E[现金收款]
    D -->|医保| F[医保结算]
    D -->|商保| G[商保结算]
    E --> H[打印发票]
    F --> H
    G --> H
    H --> I[完成]

    C -->|退费申请| J[退费审核]
    J --> K[退费执行]
    K --> L[退费完成]

    style A fill:#165DFF,color:#fff
    style I fill:#00B42A,color:#fff
    style L fill:#FF7D00,color:#fff
```

**前端页面（5 页已实现 UI）:**
| 页面 | 功能 |
|------|------|
| 收费结算 | 费用录入、结算、支付 |
| 退费管理 | 退费申请、审核、执行 |
| 结算查询 | 历史结算记录查询 |
| 日结交班 | 收费员日结对账 |
| 营收统计 | 科室/医生/时段营收分析 |

> ⚠️ 后端待实现

---

## 六、系统管理流程

### RBAC 权限流程

```mermaid
flowchart LR
    A[用户] -->|N:N| B[角色]
    B -->|N:N| C[权限]
    C -->|类型| D[菜单]
    C -->|类型| E[页面]
    C -->|类型| F[按钮]

    style A fill:#165DFF,color:#fff
    style B fill:#FF7D00,color:#fff
    style C fill:#00B42A,color:#fff
```

**预置角色:**
| 角色 | 角色码 | 权限范围 |
|------|--------|----------|
| 管理员 | ROLE_ADMIN | 全部权限 |
| 医生 | ROLE_DOCTOR | HIS业务 + 基础数据 + 住院 |
| 检验技师 | ROLE_LAB_TECH | LIS检验全部 |

**权限标识规范:** `模块:子模块:操作`
- 示例: `his:patient:view`, `charge:settle:view`, `lis:worklist:view`

---

## 八、电子病历流程 (EMR)

### 病历状态机

```mermaid
stateDiagram-v2
    [*] --> DRAFT: 新建病历
    DRAFT --> PENDING_L1: 提交一级审签
    PENDING_L1 --> PENDING_L2: 通过
    PENDING_L1 --> DRAFT: 退回
    PENDING_L2 --> PENDING_L3: 通过
    PENDING_L2 --> DRAFT: 退回
    PENDING_L3 --> APPROVED: 通过
    PENDING_L3 --> DRAFT: 退回
    APPROVED --> ARCHIVED: 归档
    APPROVED --> [*]
    ARCHIVED --> [*]
```

### 编辑流程

```mermaid
flowchart TD
    A[病历列表] --> B{状态?}
    B -->|DRAFT| C[点击编辑]
    B -->|非DRAFT| D[点击查看]
    
    C --> E[加载病历内容]
    E --> F[加载模板<br>按docType过滤]
    F --> G{内容为空?}
    G -->|是| H[自动应用模板]
    G -->|否| I[保留已有内容]
    H --> J[WangEditor可编辑]
    I --> J
    J --> K[用户编辑]
    K --> L[点击保存]
    L --> M{PUT 保存}
    M -->|后端校验通过| N[保存成功]
    M -->|status非DRAFT| O[报错提示]
    O --> J

    D --> P[加载病历内容]
    P --> Q[WangEditor只读渲染]
    Q --> R[关闭查看]

    style C fill:#165DFF,color:#fff
    style D fill:#FF7D00,color:#fff
    style N fill:#00B42A,color:#fff
```

### 模板自动匹配规则

- 门诊病历 (OUTPATIENT_RECORD) → 门诊病历模板
- 入院记录 (ADMISSION_RECORD) → 入院记录模板  
- 病程记录 (PROGRESS_NOTE) → 日常病程记录模板
- 仅当日志内容为空（新建/未编辑）时自动应用模板内容
- 已有内容的病历只选中模板但不覆盖

### 审签流程

```mermaid
flowchart LR
    A[医生提交] --> B[一级审签<br>自查]
    B -->|通过| C[二级审签<br>主治审核]
    B -->|退回| A
    C -->|通过| D[三级审签<br>质控终审]
    C -->|退回| A
    D -->|通过| E[已通过]
    D -->|退回| A
    E -->|归档| F[已归档]
```

### 实现文件

- 前端: `frontend/src/views/emr/EmrManagement.vue` + `frontend/src/components/WangEditor.vue`
- API: `frontend/src/api/emr.js`
- 后端: `EmrDocumentController` → `EmrDocumentServiceImpl` → `EmrDocument` Entity
- 模板: `EmrTemplateController` → `EmrTemplateRepository.findAvailableTemplates()`
- 测试: `EmrDocumentServiceTest.java`（8个用例）

---

## 九、药房管理流程

### 药品采购入库流程

```mermaid
flowchart TD
    A[新建采购订单] --> B[DRAFT]
    B --> C[提交审批]
    C --> D{PENDING_APPROVAL}
    D -->|通过| E[APPROVED]
    D -->|退回| B
    E --> F[执行入库]
    F --> G[创建批次记录]
    G --> H[增加库存]
    H --> I[创建库存变动记录]
    I --> J[COMPLETED]

    style A fill:#165DFF,color:#fff
    style J fill:#00B42A,color:#fff
```

### 发药流程（FIFO）

```mermaid
flowchart TD
    A[医生开处方] --> B[处方待发药]
    B --> C[药房调取处方]
    C --> D[查询库存批次]
    D --> E[按有效期FIFO选择]
    E --> F{库存充足?}
    F -->|是| G[扣减批次库存]
    F -->|否| H[提示缺药]
    H --> D
    G --> I[创建发药记录]
    I --> J[处方状态→DISPENSED]

    style A fill:#165DFF,color:#fff
    style J fill:#00B42A,color:#fff
```

### 采购单状态机

```mermaid
stateDiagram-v2
    [*] --> DRAFT: 新建
    DRAFT --> PENDING_APPROVAL: 提审
    PENDING_APPROVAL --> APPROVED: 审核通过
    PENDING_APPROVAL --> DRAFT: 退回
    APPROVED --> COMPLETED: 入库完成
    APPROVED --> CANCELLED: 取消
    PENDING_APPROVAL --> CANCELLED: 取消
    DRAFT --> CANCELLED: 取消
    COMPLETED --> [*]
    CANCELLED --> [*]
```

### 实现文件

- 前端: `pharmacy/DrugCatalog.vue` + `PurchaseOrder.vue`
- API: `api/pharmacy/index.js`
- 后端: 6个Controller

---

## 十、处方管理流程

### 处方创建流程

```mermaid
flowchart TD
    A[医生选患者] --> B[点击开处方]
    B --> C[搜索添加药品]
    C --> D[填写用量/频次/天数]
    D --> E[保存草稿]
    E --> F[DRAFT]
    F --> G[PAID 待缴费]
    G --> H[DISPENSED 已发药]

    style A fill:#165DFF,color:#fff
    style H fill:#00B42A,color:#fff
```

### 处方状态机

```mermaid
stateDiagram-v2
    [*] --> DRAFT: 新建
    DRAFT --> PAID: 收费
    DRAFT --> CANCELLED: 取消
    PAID --> DISPENSED: 发药
    PAID --> CANCELLED: 退费
    DISPENSED --> [*]
    CANCELLED --> [*]
```

---

## 十一、医生诊间工作站

### 患者就诊流程

```mermaid
flowchart TD
    A[候诊列表] --> B[开始就诊]
    B -->|REGISTERED→VISITED| C[诊疗操作]
    C --> D[病历]
    C --> E[处方]
    C --> F[检验申请]
    D --> C
    E --> C
    F --> C

    style A fill:#165DFF,color:#fff
    style C fill:#00B42A,color:#fff
```

### 实现文件

- 前端: `doctor/MyPatients.vue` + `DoctorWorkstation.vue`
- API: `api/doctor.js`

---

## 业务模块与页面/表的对应关系（完整版）

| 业务模块 | 页面 | 数据库表 | API文件 |
|----------|------|----------|---------|
| 患者管理 | PatientManagement | patient | patient.js |
| 挂号管理 | RegistrationManagement | registration | registration.js |
| 医生管理 | DoctorManagement | his_doctor | his.js |
| 医生排班 | ScheduleManagement | — | schedule.js |
| **药房** | DrugCatalog / PurchaseOrder | drug_catalog, stock_batch, purchase_order 等6张 | pharmacy/index.js |
| **处方** | MyPatients (弹窗) | prescription / prescription_item | doctor.js |
| 住院登记 | AdmissionManagement | inpatient_admissions | inpatient.js |
| 影像管理 | ImageManagement | pacs_image_study | pacs.js |
| **电子病历** | **EmrManagement** | **emr_document, audit_trail, template** | **emr.js** |
| 科室管理 | DepartmentManagement | departments | base.js |
| 病房管理 | WardManagement | wards | base.js |
| 床位管理 | BedManagement | beds | base.js |
| 数据字典 | DictManagement | dict_types + dict_items | system.js |
| 用户管理 | UserManagement | users + user_roles | system.js |
| 角色管理 | RoleManagement | roles + role_permissions | system.js |
| 权限管理 | PermissionManagement | permissions | system.js |
| 审计日志 | AuditLogManagement | audit_log | system.js |
| 系统参数 | ParameterManagement | system_config | system.js |

---

## 八、电子病历流程 (EMR)

### 病历状态机

```mermaid
stateDiagram-v2
    [*] --> DRAFT: 新建病历
    DRAFT --> PENDING_L1: 提交一级审签
    PENDING_L1 --> PENDING_L2: 通过
    PENDING_L1 --> DRAFT: 退回
    PENDING_L2 --> PENDING_L3: 通过
    PENDING_L2 --> DRAFT: 退回
    PENDING_L3 --> APPROVED: 通过
    PENDING_L3 --> DRAFT: 退回
    APPROVED --> ARCHIVED: 归档
    APPROVED --> [*]
    ARCHIVED --> [*]
```

### 编辑流程

```mermaid
flowchart TD
    A[病历列表] --> B{状态?}
    B -->|DRAFT| C[点击编辑]
    B -->|非DRAFT| D[点击查看]
    
    C --> E[加载病历内容]
    E --> F[加载模板<br>按docType过滤]
    F --> G{内容为空?}
    G -->|是| H[自动应用模板]
    G -->|否| I[保留已有内容]
    H --> J[WangEditor可编辑]
    I --> J
    J --> K[用户编辑]
    K --> L[点击保存]
    L --> M{PUT 保存}
    M -->|后端校验通过| N[保存成功]
    M -->|status非DRAFT| O[报错提示]
    O --> J

    D --> P[加载病历内容]
    P --> Q[WangEditor只读渲染]
    Q --> R[关闭查看]

    style C fill:#165DFF,color:#fff
    style D fill:#FF7D00,color:#fff
    style N fill:#00B42A,color:#fff
```

### 模板自动匹配规则

- 门诊病历 (OUTPATIENT_RECORD) → 门诊病历模板
- 入院记录 (ADMISSION_RECORD) → 入院记录模板  
- 病程记录 (PROGRESS_NOTE) → 日常病程记录模板
- 仅当日志内容为空（新建/未编辑）时自动应用模板内容
- 已有内容的病历只选中模板但不覆盖

### 审签流程

```mermaid
flowchart LR
    A[医生提交] --> B[一级审签<br>自查]
    B -->|通过| C[二级审签<br>主治审核]
    B -->|退回| A
    C -->|通过| D[三级审签<br>质控终审]
    C -->|退回| A
    D -->|通过| E[已通过]
    D -->|退回| A
    E -->|归档| F[已归档]
```

### 实现文件

- 前端: `frontend/src/views/emr/EmrManagement.vue` + `frontend/src/components/WangEditor.vue`
- API: `frontend/src/api/emr.js`
- 后端: `EmrDocumentController` → `EmrDocumentServiceImpl` → `EmrDocument` Entity
- 模板: `EmrTemplateController` → `EmrTemplateRepository.findAvailableTemplates()`
- 测试: `EmrDocumentServiceTest.java`（8个用例）

---

*相关文档: [[05_HIS_实际数据库表]] [[06_HIS_UI页面与路由]] [[08_HIS_数据流程]]*
*标签: #HIS #业务流程 #BPMN #Mermaid*
