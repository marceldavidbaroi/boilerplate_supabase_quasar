<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-xl">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">Workspace Settings</h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Configure branding, preferences, and details for your organization.
        </p>
      </div>
    </div>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <!-- Success Banner -->
    <q-banner v-if="successMsg" class="bg-green-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="check_circle" color="white" />
      </template>
      {{ successMsg }}
    </q-banner>

    <div class="row q-col-gutter-lg">
      <!-- Settings Form -->
      <div class="col-12 col-md-8">
        <q-card class="glass-card">
          <q-card-section class="q-py-md border-bottom">
            <div class="text-h6 text-bold text-slate-800">Branding & Appearance</div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <q-form @submit.prevent="saveSettings" class="q-gutter-y-md">
              <div>
                <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                  >Workspace Name (Read-Only)</label
                >
                <q-input v-model="workspaceName" filled disable class="custom-input" />
              </div>

              <div>
                <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                  >Workspace Slug (Read-Only)</label
                >
                <q-input v-model="workspaceSlug" filled disable class="custom-input" />
              </div>

              <div>
                <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                  >Branding Logo URL</label
                >
                <q-input
                  v-model="logoUrl"
                  type="url"
                  filled
                  placeholder="https://example.com/logo.png"
                  color="primary"
                  class="custom-input"
                  :disable="!canEdit"
                />
              </div>

              <div>
                <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                  >Theme Theme Color Hex</label
                >
                <q-input
                  v-model="themeColor"
                  filled
                  placeholder="#6366f1"
                  color="primary"
                  class="custom-input"
                  :disable="!canEdit"
                  :rules="[
                    (val) => !val || /^#[0-9A-F]{6}$/i.test(val) || 'Must be a valid hex color',
                  ]"
                  hide-bottom-space
                >
                  <template #append>
                    <q-icon name="colorize" class="cursor-pointer">
                      <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                        <q-color v-model="themeColor" />
                      </q-popup-proxy>
                    </q-icon>
                  </template>
                </q-input>
              </div>

              <div class="q-mt-xl" v-if="canEdit">
                <q-btn
                  type="submit"
                  color="primary"
                  label="Save Changes"
                  class="q-px-lg rounded-btn btn-gradient text-weight-bold"
                  :loading="saving"
                />
              </div>
            </q-form>
          </q-card-section>
        </q-card>
      </div>

      <!-- Settings Overview/Help -->
      <div class="col-12 col-md-4">
        <q-card class="glass-card full-height">
          <q-card-section class="q-py-md border-bottom row items-center">
            <q-icon name="shield" size="24px" class="text-amber-800 q-mr-sm" />
            <div class="text-h6 text-bold text-slate-800">Access Scopes</div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div class="text-subtitle2 q-mb-sm text-amber-9">Editing Privileges</div>
            <p class="text-sm text-slate-500 q-mb-lg">
              Branding settings are only configurable by users with the
              <span class="text-slate-800 text-weight-bold">Owner</span> or
              <span class="text-slate-800 text-weight-bold">Admin</span> role. Normal members can
              only view settings.
            </p>

            <div class="text-subtitle2 q-mb-sm text-indigo-8">Subscription Plan</div>
            <p class="text-sm text-slate-500">
              Feature flags and subscription tiers are platform-level policies that can only be
              altered by a platform superadmin in the superadmin portal.
            </p>
          </q-card-section>
        </q-card>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import { updateTenantSettings } from '../../services/multiTenant';

const tenantStore = useTenantStore();

const workspaceName = ref('');
const workspaceSlug = ref('');
const logoUrl = ref('');
const themeColor = ref('');

const saving = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const canEdit = computed(() => {
  return (
    tenantStore.activeRole === 'Owner' ||
    tenantStore.activeRole === 'Admin' ||
    tenantStore.isSuperadmin
  );
});

const loadTenantSettingsData = () => {
  if (!tenantStore.activeTenant) return;
  workspaceName.value = tenantStore.activeTenant.name;
  workspaceSlug.value = tenantStore.activeTenant.slug;
  logoUrl.value = tenantStore.activeSettings?.logo_url || '';
  themeColor.value = tenantStore.activeSettings?.theme_color || '';
};

const saveSettings = async () => {
  if (!tenantStore.activeTenant) return;
  saving.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const updated = await updateTenantSettings(tenantStore.activeTenant.id, {
      logo_url: logoUrl.value || null,
      theme_color: themeColor.value || null,
    });

    // Refresh settings in store
    tenantStore.activeSettings = updated;
    successMsg.value = 'Workspace settings updated successfully!';
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update settings.';
  } finally {
    saving.value = false;
  }
};

onMounted(() => {
  loadTenantSettingsData();
});
</script>

<style scoped lang="scss">
.glass-card {
  background: #ffffff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.rounded-btn {
  border-radius: 12px;
}

.btn-gradient {
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.15);
  border: none;

  &:hover {
    filter: brightness(1.1);
  }
}

.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #ffffff !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;

  &:hover {
    border-color: #94a3b8;
  }
}
</style>
