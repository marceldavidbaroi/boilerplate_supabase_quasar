<template>
  <q-layout view="hHh Lpr lFf" class="workspace-layout">
    <!-- Header -->
    <q-header elevated class="bg-slate-950 border-bottom text-slate-800">
      <q-toolbar class="q-py-sm">
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          class="q-mr-sm text-slate-600"
          @click="toggleLeftDrawer"
        />

        <!-- Tenant Switcher Selector -->
        <div class="tenant-switcher-container">
          <q-btn-dropdown
            flat
            no-caps
            class="tenant-dropdown-btn"
            content-class="tenant-dropdown-menu"
          >
            <template #label>
              <div class="row items-center no-wrap">
                <q-avatar size="28px" class="q-mr-sm tenant-avatar text-white">
                  {{ activeTenantNameInitials }}
                </q-avatar>
                <div class="text-left">
                  <div class="text-weight-bold text-slate-900 leading-tight">
                    {{ tenantStore.activeTenant?.name || 'Loading...' }}
                  </div>
                  <div class="text-caption text-slate-500 leading-none">
                    {{ tenantStore.activeRole || 'Member' }}
                  </div>
                </div>
              </div>
            </template>

            <!-- Dropdown List of Tenants -->
            <q-list class="q-py-xs bg-slate-950 text-slate-900 border-all">
              <q-item-label header class="text-slate-500 text-xs font-semibold q-pb-xs">
                Switch Workspace
              </q-item-label>

              <q-item
                v-for="membership in tenantStore.myTenants"
                :key="membership.id"
                clickable
                v-close-popup
                :active="membership.tenants?.id === tenantStore.activeTenant?.id"
                active-class="active-tenant-item"
                class="q-py-sm tenant-select-item"
                @click="switchWorkspace(membership.tenants?.slug)"
              >
                <q-item-section avatar>
                  <q-avatar size="32px" class="tenant-avatar-small">
                    {{ getInitials(membership.tenants?.name || '') }}
                  </q-avatar>
                </q-item-section>
                <q-item-section>
                  <q-item-label class="text-weight-bold">
                    {{ membership.tenants?.name }}
                  </q-item-label>
                  <q-item-label caption class="text-slate-500">
                    {{ membership.tenant_roles?.name || 'Member' }}
                  </q-item-label>
                </q-item-section>
                <q-item-section side v-if="membership.tenants?.id === tenantStore.activeTenant?.id">
                  <q-icon name="check" color="primary" size="18px" />
                </q-item-section>
              </q-item>

              <!-- Optional Superadmin redirect -->
              <q-separator class="q-my-sm" v-if="tenantStore.isSuperadmin" />
              <q-item
                v-if="tenantStore.isSuperadmin"
                clickable
                v-close-popup
                to="/admin/dashboard"
                class="q-py-sm text-amber-900"
              >
                <q-item-section avatar>
                  <q-icon name="admin_panel_settings" size="24px" />
                </q-item-section>
                <q-item-section>
                  <q-item-label class="text-weight-bold">Superadmin Portal</q-item-label>
                </q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </div>

        <q-space />

        <!-- User Profile Dropdown -->
        <div class="row items-center no-wrap">
          <q-btn-dropdown flat round dense class="user-dropdown-btn">
            <template #label>
              <q-avatar size="32px" class="user-avatar text-white">
                <img
                  v-if="tenantStore.userProfile?.avatar_url"
                  :src="tenantStore.userProfile.avatar_url"
                />
                <span v-else>{{ userInitials }}</span>
              </q-avatar>
            </template>

            <q-list style="min-width: 220px" class="bg-slate-950 text-slate-900 border-all q-py-sm">
              <div class="q-px-md q-py-sm">
                <div class="text-weight-bold">
                  {{ tenantStore.userProfile?.full_name || 'User Profile' }}
                </div>
                <div class="text-caption text-slate-500">{{ tenantStore.user?.email }}</div>
                <div v-if="tenantStore.isSuperadmin" class="q-mt-xs">
                  <q-badge color="amber" class="text-black text-weight-bold">Superadmin</q-badge>
                </div>
              </div>

              <q-separator class="q-my-sm" />

              <q-item clickable v-close-popup :to="`/${tenantStore.activeTenant?.slug}/settings`">
                <q-item-section avatar>
                  <q-icon name="settings" size="20px" class="text-slate-500" />
                </q-item-section>
                <q-item-section>Workspace Settings</q-item-section>
              </q-item>

              <q-item clickable v-close-popup @click="handleSignOut" class="text-negative">
                <q-item-section avatar>
                  <q-icon name="logout" size="20px" color="negative" />
                </q-item-section>
                <q-item-section>Sign Out</q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </div>
      </q-toolbar>
    </q-header>

    <!-- Sidebar Navigation Drawer -->
    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
      class="bg-slate-950 text-slate-900 border-right"
      :width="260"
    >
      <div class="drawer-content flex flex-col justify-between">
        <div>
          <!-- Workspace Title / Header -->
          <div class="q-pa-md brand-section border-bottom flex items-center">
            <q-icon name="workspaces" size="28px" class="text-primary q-mr-sm" />
            <div>
              <div class="text-weight-bold text-slate-900 text-subtitle1 leading-tight">
                {{ tenantStore.activeTenant?.name || 'Workspace' }}
              </div>
              <div class="text-xs text-slate-500">
                {{ tenantStore.activeTenant?.slug }}
              </div>
            </div>
          </div>

          <!-- Navigation Links -->
          <q-list class="q-px-sm q-py-md">
            <q-item
              v-for="item in navItems"
              :key="item.toName"
              clickable
              exact
              :to="{ name: item.toName, params: { tenantSlug: tenantStore.activeTenant?.slug } }"
              class="nav-link-item q-mb-sm"
              active-class="nav-active-item"
            >
              <q-item-section avatar>
                <q-icon :name="item.icon" size="22px" />
              </q-item-section>
              <q-item-section>{{ item.label }}</q-item-section>
            </q-item>
          </q-list>
        </div>

        <!-- Footer / Version -->
        <div class="q-pa-md text-center text-xs text-slate-400 border-top">
          Powered by Supabase + Quasar
        </div>
      </div>
    </q-drawer>

    <!-- Page Container -->
    <q-page-container class="bg-slate-900 text-slate-800 min-h-screen">
      <router-view v-slot="{ Component }">
        <transition name="fade-slide" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useTenantStore } from '../stores/tenant';

const router = useRouter();
const tenantStore = useTenantStore();
const leftDrawerOpen = ref(true);

interface NavItem {
  label: string;
  icon: string;
  toName: string;
  requiredFeature?: string;
  requiredPermission?: string;
}

const navItems = computed<NavItem[]>(() => {
  const items: NavItem[] = [
    {
      label: 'Dashboard',
      icon: 'dashboard',
      toName: 'workspace-dashboard',
    },
    {
      label: 'CRM',
      icon: 'stars',
      toName: 'workspace-crm',
      requiredFeature: 'crm',
      requiredPermission: 'crm',
    },
    {
      label: 'Invoicing',
      icon: 'receipt',
      toName: 'workspace-invoicing',
      requiredFeature: 'invoicing',
      requiredPermission: 'invoicing',
    },
    {
      label: 'Chat',
      icon: 'chat',
      toName: 'workspace-chat',
      requiredFeature: 'chat',
      requiredPermission: 'chat',
    },
    {
      label: 'Members',
      icon: 'people',
      toName: 'workspace-members',
      requiredPermission: 'members',
    },
    {
      label: 'Settings',
      icon: 'settings',
      toName: 'workspace-settings',
      requiredPermission: 'settings',
    },
  ];

  return items.filter((item) => {
    if (item.requiredFeature && !tenantStore.isFeatureEnabled(item.requiredFeature)) {
      return false;
    }
    if (item.requiredPermission && !tenantStore.hasPermission(item.requiredPermission, 'read')) {
      return false;
    }
    return true;
  });
});

const toggleLeftDrawer = () => {
  leftDrawerOpen.value = !leftDrawerOpen.value;
};

const getInitials = (name: string) => {
  if (!name) return 'WS';
  return name
    .split(' ')
    .map((word) => word[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();
};

const activeTenantNameInitials = computed(() => {
  return getInitials(tenantStore.activeTenant?.name || '');
});

const userInitials = computed(() => {
  const profileName = tenantStore.userProfile?.full_name || tenantStore.user?.email || '';
  return getInitials(profileName);
});

const switchWorkspace = async (slug?: string) => {
  if (!slug) return;
  await router.push(`/${slug}/dashboard`);
};

const handleSignOut = async () => {
  await tenantStore.logout();
  await router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.workspace-layout {
  font-family: 'Outfit', 'Inter', sans-serif;
  background-color: #f8fafc;
}

.bg-slate-900 {
  background-color: #f8fafc !important;
}

.bg-slate-950 {
  background-color: #ffffff !important;
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.border-right {
  border-right: 1px solid rgba(0, 0, 0, 0.06);
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.tenant-dropdown-btn {
  padding: 4px 12px;
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #f8fafc;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    border-color: #94a3b8;
  }
}

.tenant-avatar {
  background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
  font-weight: 700;
  border: 1.5px solid rgba(255, 255, 255, 0.2);
}

.tenant-avatar-small {
  background: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
  color: white;
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.user-avatar {
  background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.2);
  cursor: pointer;
}

.tenant-dropdown-menu {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
  border-radius: 12px;
  overflow: hidden;
}

.tenant-select-item {
  border-radius: 8px;
  margin: 4px 8px;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
  }
}

.active-tenant-item {
  background: rgba(99, 102, 241, 0.08) !important;
  color: #4f46e5 !important;
}

.nav-link-item {
  border-radius: 12px;
  color: #475569;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    color: #0f172a;
  }
}

.nav-active-item {
  background: rgba(99, 102, 241, 0.08) !important;
  color: #4f46e5 !important;
  border-left: 3px solid #6366f1;
  font-weight: 600;
}

.drawer-content {
  height: 100%;
}

.brand-section {
  height: 64px;
}

/* Transitions */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
