---
created: 2026-04-28
tags: #主题, #权限, #RBAC, #安全
related: "[[HIS-LIS-PACS 实施进度]]", "[[HIS-LIS-PACS 规划]]"
---

# RBAC 权限系统

> 基于角色的访问控制 (Role-Based Access Control)
> 实现于 HIS/LIS/PACS 项目

## 数据模型

```
User ──ManyToMany── Role ──ManyToMany── Permission
  │                   │                     │
  └─ user_roles ──────┘                     │
                      └─ role_permissions ──┘
```

## 权限标识规范

格式: `模块:资源:操作`

| 前缀 | 模块 |
|------|------|
| `dashboard` | 仪表盘 |
| `his:patient` | 患者管理 |
| `his:doctor` | 医生管理 |
| `his:registration` | 挂号管理 |
| `his:charge` | 收费管理 |
| `lis:worklist` | 检验工作列表 |
| `lis:sample` | 样本管理 |
| `lis:test` | 检验项目 |
| `lis:report` | 检验报告 |
| `pacs:image` | 影像管理 |
| `pacs:diagnosis` | 影像诊断 |
| `base` | 基础数据（科室/病房/床位） |
| `inpatient:admission` | 住院登记 |
| `system` | 系统管理（用户/角色/权限/字典/参数/审计） |
| `settings` | 系统设置 |

操作: `view` / `create` / `edit` / `delete` / `upload` / `audit`

## 技术实现

### 后端
- `JwtResponse` 登录时返回 `permissions: List<String>`
- `AuthServiceImpl.login()` 加 `@Transactional` 遍历角色收集权限
- `init-rbac.sql` 预置 44 条权限 + 3 个角色

### 前端
- `userStore` 存储 permissions 数组 + `hasPermission(code)` getter
- 路由 `meta.permission` 标识所需权限
- 路由守卫: 无权限 → 跳转 dashboard
- `MainLayout` 侧边栏: `v-if="hasPerm(...)"` 动态过滤菜单

## 角色定义

| 角色 | 角色码 | 权限数 | 可见范围 |
|------|--------|:------:|----------|
| 管理员 | `ROLE_ADMIN` | 44 | 全部菜单 |
| 医生 | `ROLE_DOCTOR` | 11 | 仪表盘 + HIS + 基础数据 + 住院 |
| 检验技师 | `ROLE_LAB_TECH` | 11 | 仪表盘 + LIS + 科室 |

## 关键决策

- 权限标识用字符串（`module:resource:action`）而非数字 ID，可读性强
- 角色权限预置在 SQL 中，启动时执行，不依赖前端动态配置
- 侧边栏子菜单：无可见子项时整组隐藏
- 权限持久化到 localStorage，刷新不丢失
