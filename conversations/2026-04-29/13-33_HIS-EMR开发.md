---
created: 2026-04-29 13:33
tags: #对话, #HIS, #EMR
topic: HIS EMR 电子病历 + 排班 + 用户医生打通
channel: 飞书
related: "[[HIS-LIS-PACS 实施进度]]", "[[09_EMR_电子病历设计]]"
---

# 对话 | HIS EMR + 排班 + 用户医生打通

**日期:** 2026-04-29
**用户:** 湫
**渠道:** 飞书
**话题:** HIS 系统多项功能完善

## 关键内容

### 1. 用户管理编辑用户波及其他账户 —— 修复
- 根因：`handleEdit` 未加载已有 roleIds，`form.roleIds` 残留上次操作的值
- 修复：编辑时 `resetForm()` + 调用 `GET /users/{id}` 加载角色

### 2. 挂号业务流程完整设计
- 四步流程：选患者 → 选门诊科室 → 选在班医生 → 确认付费
- 科室类型新增 `outpatient`（门诊科室），仅门诊科室可挂号
- 挂号费从 `system_config` 读取（registration.fee = ¥15.00）

### 3. 医生排班模块（重写）
- 新建 `doctor_schedule` 表，支持 MORNING/AFTERNOON/EVENING 班次
- 排班管理页面：周视图 + 批量排班
- 挂号只显示当天在班医生

### 4. 医生+用户数据打通
- `his_doctor` 加 `user_id` 列关联 `users`
- 用户管理选医生角色 → 自动创建医生档案
- 医生管理页面去掉新增按钮，仅编辑
- 挂号查询只返回 `user_id IS NOT NULL` 的医生

### 5. EMR 电子病历模块（新建）
- 3 张表：`emr_document` / `emr_audit_trail` / `emr_template`
- 三级质控：DRAFT → PENDING_L1 → PENDING_L2 → PENDING_L3 → APPROVED → ARCHIVED
- 支持门诊病历、入院记录、病程记录
- 12 个 API 端点 + 前端页面（列表/编辑器/审签/归档）
- 3 个预置模板

### 6. 子代理模型配置
- 配置改为 ark-code-latest（Volcengine Ark）
- API Key 从桌面 key.txt 读取
- claude-code-haha 的 .env 和 ACP 配置已更新

## 相关链接
- [[HIS-LIS-PACS 实施进度]]
- [[09_EMR_电子病历设计]]
- [[05_HIS_实际数据库表]]
- [[06_HIS_UI页面与路由]]
- [[07_HIS_业务流程]]
- [[08_HIS_数据流程]]
