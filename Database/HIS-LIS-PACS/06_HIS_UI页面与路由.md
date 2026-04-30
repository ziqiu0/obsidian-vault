---
created: 2026-04-29
tags: #HIS, #前端, #Vue3, #路由, #UI
---

# HIS/UI 页面与路由

> 基于项目代码中实际的 Vue 3 路由和页面组件
> 项目: `~/projects/his-lis-pacs/frontend/`
> UI 设计规范见 [[his-lis-pacs-ui]]

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue 3 | 3.x | 前端框架 |
| Vite | 5.x | 构建工具 |
| Element Plus | 2.x | UI 组件库 |
| Pinia | 2.x | 状态管理 |
| Vue Router | 4.x | 路由管理 |
| Axios | 1.x | HTTP 请求 |

---

## 路由结构

### 公开路由

| 路径 | 页面 | 组件 | 权限 |
|------|------|------|------|
| `/login` | 登录页 | `Login.vue` | 无需认证 |

### 认证路由（MainLayout 包裹）

| 路由分组 | 路径 | 页面名称 | 组件 | 权限标识 |
|----------|------|----------|------|----------|
| **病历管理** | `emr/documents` | 电子病历 | `emr/EmrManagement.vue` | — |
| **首页** | `/dashboard` | 仪表盘 | `Dashboard.vue` | — |
| **门诊业务** | `his/patient` | 患者管理 | `his/PatientManagement.vue` | `his:patient:view` |
| | `his/doctor` | 医生排班 | `his/DoctorManagement.vue` | `his:doctor:view` |
| | `his/registration` | 挂号管理 | `his/RegistrationManagement.vue` | `his:registration:view` |
| **收费管理** | `charge/settle` | 收费结算 | `charge/SettleManagement.vue` | `charge:settle:view` |
| | `charge/refund` | 退费管理 | `charge/RefundManagement.vue` | `charge:refund:view` |
| | `charge/query` | 结算查询 | `charge/QueryManagement.vue` | `charge:query:view` |
| | `charge/daily` | 日结交班 | `charge/DailySettlement.vue` | `charge:daily:view` |
| | `charge/report` | 营收统计 | `charge/ReportStatistics.vue` | `charge:report:view` |
| **LIS 检验** | `lis/worklist` | 检验工作列表 | `lis/WorklistManagement.vue` | `lis:worklist:view` |
| | `lis/sample` | 样本管理 | `lis/SampleManagement.vue` | `lis:sample:view` |
| | `lis/test` | 检验项目 | `lis/TestItemManagement.vue` | `lis:test:view` |
| | `lis/report` | 检验报告 | `lis/TestReportManagement.vue` | `lis:report:view` |
| **PACS 影像** | `pacs/image` | 影像管理 | `pacs/ImageManagement.vue` | `pacs:image:view` |
| | `pacs/diagnosis` | 影像诊断 | `pacs/ImageDiagnosis.vue` | `pacs:diagnosis:view` |
| **住院管理** | `inpatient/admission` | 住院登记 | `inpatient/AdmissionManagement.vue` | `inpatient:admission:view` |
| **基础配置** | `base/ward` | 病房管理 | `base/WardManagement.vue` | `base:ward:view` |
| | `base/bed` | 床位管理 | `base/BedManagement.vue` | `base:bed:view` |
| | `base/department` | 科室管理 | `base/DepartmentManagement.vue` | `base:department:view` |
| | `system/dict` | 数据字典 | `system/DictManagement.vue` | `system:dict:view` |
| | `system/parameters` | 系统参数 | `system/ParameterManagement.vue` | `system:parameter:view` |
| **系统管理** | `system/users` | 用户管理 | `system/UserManagement.vue` | `system:user:view` |
| | `system/roles` | 角色管理 | `system/RoleManagement.vue` | `system:role:view` |
| | `system/department` | 科室管理(系统) | `system/DepartmentManagement.vue` | `base:department:view` |
| | `system/permissions` | 权限管理 | `system/PermissionManagement.vue` | `system:permission:view` |
| | `system/audit` | 审计日志 | `system/AuditLogManagement.vue` | `system:audit:view` |
| | `settings` | 系统设置 | `settings/SystemSettings.vue` | `settings:view` |

---

## 页面清单（按模块）

### 🏠 首页

| 页面 | 文件 | 功能 |
|------|------|------|
| 仪表盘 | `Dashboard.vue` | 系统概览、数据统计、快捷入口 |
| 登录 | `Login.vue` | JWT 认证登录 |
| 主布局 | `MainLayout.vue` | 顶部导航 + 侧边栏 + 内容区 |

### 📋 电子病历（1 页）

| 页面 | 文件 | 组件依赖 | API 文件 | 后端 |
|:----:|------|----------|----------|:----:|
| 病历管理 | `emr/EmrManagement.vue` | WangEditor.vue | `api/emr.js` | ✅ |

**EmrManagement.vue 功能清单:**
- 病历列表（分页搜索：患者ID/病历类型/状态）
- 新建病历（ElMessageBox 输入患者ID）
- 编辑模式（DRAFT状态）→ WangEditor 富文本编辑 + 模板选择
- 查看模式（非DRAFT）→ WangEditor 只读渲染
- 提交审签（三级质控）
- 审核操作（通过/退回）
- 归档

**WangEditor.vue 组件属性:**
- `v-model` / `height` / `placeholder` / `readonly`
- 工具栏排除项：视频/表格/代码块/引用/标题/全屏/图片/表情/链接/Todo
- CSS 强制左对齐

### 🏥 HIS 门诊业务（3 页）

| 页面 | 文件 | API 文件 | 对应后端 |
|------|------|----------|----------|
| 患者管理 | `his/PatientManagement.vue` | `api/patient.js` | `PatientController` |
| 医生排班 | `his/DoctorManagement.vue` | `api/his.js` | `DoctorController` |
| 挂号管理 | `his/RegistrationManagement.vue` | `api/registration.js` | `RegistrationController` |

### 💰 收费管理（5 页）

| 页面 | 文件 | 后端状态 |
|------|------|:--------:|
| 收费结算 | `charge/SettleManagement.vue` | ❌ 待实现 |
| 退费管理 | `charge/RefundManagement.vue` | ❌ 待实现 |
| 结算查询 | `charge/QueryManagement.vue` | ❌ 待实现 |
| 日结交班 | `charge/DailySettlement.vue` | ❌ 待实现 |
| 营收统计 | `charge/ReportStatistics.vue` | ❌ 待实现 |

### 🔬 LIS 检验中心（4 页）

| 页面 | 文件 | API 文件 | 后端状态 |
|------|------|----------|:--------:|
| 检验工作列表 | `lis/WorklistManagement.vue` | `api/lis.js` | ❌ |
| 样本管理 | `lis/SampleManagement.vue` | `api/lis.js` | ❌ |
| 检验项目 | `lis/TestItemManagement.vue` | `api/lis.js` | ❌ |
| 检验报告 | `lis/TestReportManagement.vue` | `api/lis.js` | ❌ |

### 📷 PACS 影像中心（2 页）

| 页面 | 文件 | API 文件 | 后端状态 |
|------|------|----------|:--------:|
| 影像管理 | `pacs/ImageManagement.vue` | `api/pacs.js` | ✅ |
| 影像诊断 | `pacs/ImageDiagnosis.vue` | `api/pacs.js` | ❌ |

### 🏨 住院管理（1 页）

| 页面 | 文件 | API 文件 | 后端状态 |
|------|------|----------|:--------:|
| 住院登记 | `inpatient/AdmissionManagement.vue` | `api/inpatient.js` | ✅ |

### ⚙️ 基础配置（5 页）

| 页面 | 文件 | API 文件 | 后端状态 |
|------|------|----------|:--------:|
| 科室管理 | `base/DepartmentManagement.vue` | `api/base.js` | ✅ |
| 病房管理 | `base/WardManagement.vue` | `api/base.js` | ✅ |
| 床位管理 | `base/BedManagement.vue` | `api/base.js` | ✅ |
| 数据字典 | `system/DictManagement.vue` | `api/system.js` | ✅ |
| 系统参数 | `system/ParameterManagement.vue` | `api/system.js` | ❌ |

### 🔧 系统管理（6 页）

| 页面 | 文件 | API 文件 | 后端状态 |
|------|------|----------|:--------:|
| 用户管理 | `system/UserManagement.vue` | `api/system.js` | ✅ |
| 角色管理 | `system/RoleManagement.vue` | `api/system.js` | ✅ |
| 科室管理(系统) | `system/DepartmentManagement.vue` | `api/system.js` | ✅ |
| 权限管理 | `system/PermissionManagement.vue` | `api/system.js` | ✅ |
| 权限树 | `system/PermissionTree.vue` | — | 组件 |
| 审计日志 | `system/AuditLogManagement.vue` | `api/system.js` | ❌ |
| 系统设置 | `settings/SystemSettings.vue` | `api/system.js` | ❌ |

---

## 前后端 API 对照

### 已实现的 API 文件

| 文件 | 模块 | 主要端点 |
|------|------|----------|
| `api/patient.js` | 患者 | CRUD + 搜索 |
| `api/registration.js` | 挂号 | 创建(四步流程) + 列表 + 状态变更 |
| `api/his.js` | HIS通用 | 医生 CRUD |
| `api/base.js` | 基础数据 | 科室/病房/床位 CRUD |
| `api/inpatient.js` | 住院 | 住院登记 CRUD |
| `api/pacs.js` | 影像 | 影像检查 CRUD |
| `api/lis.js` | 检验 | 检验相关(后端待实现) |
| `api/emr.js` | **电子病历** | 创建/查询/保存/提交审签/审核/归档 + 模板 |
| `api/system.js` | 系统 | 用户/角色/权限/字典/参数/审计 |
| `utils/request.js` | 工具 | Axios 封装 + token 拦截器 |
| `store/user.js` | 状态 | 用户登录状态 + 权限管理 |

---

## 权限路由守卫

```javascript
// router/index.js
router.beforeEach((to, from, next) => {
  // 1. 登录页已登录 → 重定向 dashboard
  // 2. 需认证页面未登录 → 重定向 login
  // 3. 需权限页面无权限 → 重定向 dashboard
})
```

---

*相关文档: [[his-lis-pacs-ui|UI设计规范]] [[05_HIS_实际数据库表]] [[07_HIS_业务流程]]*
*标签: #HIS #前端 #Vue3 #路由 #Element-Plus*
