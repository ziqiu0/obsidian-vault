---
created: 2026-04-28 17:30
tags: #对话, #AI, #飞书, #项目推进
topic: HIS-RBAC-开发
channel: 飞书
related: "[[HIS-LIS-PACS 规划]]", "[[HIS-LIS-PACS 实施进度]]", "[[RBAC 权限系统]]", "[[2026-04-28]]"
---

# 对话 | HIS 患者管理 + 挂号流程 + RBAC 权限

**日期:** 2026-04-28
**用户:** 湫
**渠道:** 飞书
**话题:** HIS/LIS/PACS 业务系统后端补全 + RBAC 权限体系搭建

## 背景

HIS/LIS/PACS 项目前端 25 个页面已基本完成，但大量模块后端 Controller/Service 缺失。本次对话以「协作教练」模式推进，按 厘清目标→深挖需求→设计方案→制定计划 四阶段进行。

## 完成工作

### 1. 患者管理 CRUD 后端补全
- 前端修复 2 个 API 调用 bug（searchPatients 参数格式、updatePatient 缺 id）
- 后端新建 PatientService + PatientServiceImpl + PatientController
- 前后端字段映射：patientId↔patientNo, allergies↔allergyHistory 等

### 2. 挂号管理模块（全栈新建）
- 需求深挖：Registration 实体含患者快照（全字段）、挂号时间、就诊序号、费用、状态
- 后端 7 个文件：Entity/Repository/DTO/Service/Controller
- 前端四步流程页面：选患者→选科室→选医生→确认挂号
- 关键特性：患者快照自动填充、当天序号自增（默认 0）

### 3. RBAC 权限控制链路（全栈）
- 后端：JwtResponse 新增 permissions 字段，AuthServiceImpl 加 @Transactional 提取权限
- 数据库：init-rbac.sql — 44 条预置权限 + 3 个角色
  - `admin` — 全部权限
  - `doctor` — HIS 业务（患者/医生/挂号/收费/住院）
  - `lab_tech` — LIS 检验全部
- 前端：userStore 新增 permissions + hasPermission getter
- 路由：所有路由加 permission 元数据 + 权限守卫
- 侧边栏：菜单项按角色动态过滤

## 关键决策

- 挂号设计选择「患者快照」方案（非仅关联 ID），便于后续病历病程、医嘱执行
- RBAC 采用 permissionKey 字符串匹配（如 `his:patient:view`），灵活可扩展
- 角色权限采用静态预置 + 数据库持久化，启动时执行 init-rbac.sql

## 项目当前状态

前端 25 页 → 全部完成
后端 Controller → 已补齐 15 个（Auth/User/Role/Permission/Doctor/Patient/Registration/DictType/DictItem/Department/Bed/Ward/ImageStudy/Admission + 集成平台 2 个）
剩余缺口：LIS 4 页后端、收费管理后端、系统设置后端

## 相关链接

- [[HIS-LIS-PACS 规划]] — 总体架构规划
- [[HIS-LIS-PACS 实施进度]] — 实施进度 MOC
- [[RBAC 权限系统]] — 权限设计
