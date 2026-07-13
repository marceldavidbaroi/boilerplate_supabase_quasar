<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-xl">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">Members Management</h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Manage team members, roles, and pending invitations for this workspace.
        </p>
      </div>
      <div>
        <q-btn
          v-if="canManage"
          color="primary"
          icon="person_add"
          label="Invite Member"
          class="rounded-btn q-px-md"
          @click="showInviteDialog = true"
        />
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

    <!-- Members List Table -->
    <q-card class="glass-card">
      <q-card-section class="q-py-md border-bottom row items-center justify-between">
        <div class="text-h6 text-bold text-slate-800">Team Members</div>
        <q-btn
          flat
          round
          dense
          icon="refresh"
          color="grey-7"
          @click="loadMembers"
          :loading="loadingMembers"
        />
      </q-card-section>

      <q-table
        :rows="members"
        :columns="columns"
        row-key="id"
        flat
        binary-state-sort
        class="bg-transparent border-none text-slate-800"
        :loading="loadingMembers"
        no-data-label="No members found in this workspace"
      >
        <!-- Custom Avatar and Profile Slot -->
        <template #body-cell-user="props">
          <q-td :props="props">
            <div class="row items-center no-wrap">
              <q-avatar size="32px" class="q-mr-sm member-table-avatar">
                <img
                  v-if="props.row.user_profile?.avatar_url"
                  :src="props.row.user_profile.avatar_url"
                />
                <span v-else>{{ getInitials(props.row.user_profile?.full_name || 'Member') }}</span>
              </q-avatar>
              <div>
                <div class="text-weight-bold text-white">
                  {{ props.row.user_profile?.full_name || 'Unregistered User' }}
                </div>
                <div class="text-caption text-grey-4 font-mono">{{ props.row.user_id }}</div>
              </div>
            </div>
          </q-td>
        </template>

        <!-- Custom Role Slot -->
        <template #body-cell-role="props">
          <q-td :props="props">
            <q-badge outline color="primary" class="q-py-xs q-px-sm font-semibold">
              {{ props.row.tenant_roles?.name || 'Member' }}
            </q-badge>
          </q-td>
        </template>

        <!-- Custom Status Slot -->
        <template #body-cell-status="props">
          <q-td :props="props">
            <q-badge
              :color="props.row.status === 'active' ? 'positive' : 'negative'"
              class="text-weight-bold text-black uppercase"
            >
              {{ props.row.status }}
            </q-badge>
          </q-td>
        </template>

        <!-- Custom Actions Slot -->
        <template #body-cell-actions="props">
          <q-td :props="props" class="text-right">
            <q-btn
              v-if="
                canManage &&
                props.row.user_id !== tenantStore.user?.id &&
                props.row.tenant_roles?.name !== 'Owner'
              "
              flat
              round
              dense
              icon="delete"
              color="negative"
              @click="confirmRemove(props.row)"
            >
              <q-tooltip>Remove Member</q-tooltip>
            </q-btn>
            <span v-else class="text-caption text-grey-5">N/A</span>
          </q-td>
        </template>
      </q-table>
    </q-card>

    <!-- Pending Invitations Card -->
    <q-card class="glass-card q-mt-lg">
      <q-card-section class="q-py-md border-bottom row items-center justify-between">
        <div class="text-h6 text-bold text-slate-800">Pending Invitations</div>
        <q-btn
          flat
          round
          dense
          icon="refresh"
          color="grey-7"
          @click="loadInvitations"
          :loading="loadingInvitations"
        />
      </q-card-section>

      <q-table
        :rows="invitations"
        :columns="invitationsColumns"
        row-key="id"
        flat
        binary-state-sort
        class="bg-transparent border-none text-slate-800"
        :loading="loadingInvitations"
        no-data-label="No pending invitations for this workspace"
      >
        <!-- Custom Role Slot -->
        <template #body-cell-role="props">
          <q-td :props="props">
            <q-badge outline color="primary" class="q-py-xs q-px-sm font-semibold">
              {{ props.row.tenant_roles?.name || 'Member' }}
            </q-badge>
          </q-td>
        </template>

        <!-- Custom Status Slot -->
        <template #body-cell-status="props">
          <q-td :props="props">
            <q-badge color="warning" class="text-weight-bold text-black uppercase">
              {{ props.row.status }}
            </q-badge>
          </q-td>
        </template>

        <!-- Custom Expires At Slot -->
        <template #body-cell-expires_at="props">
          <q-td :props="props">
            {{ formatDate(props.row.expires_at) }}
          </q-td>
        </template>

        <!-- Custom Actions Slot -->
        <template #body-cell-actions="props">
          <q-td :props="props" class="text-right">
            <q-btn
              v-if="canManage"
              flat
              round
              dense
              icon="cancel"
              color="negative"
              @click="confirmCancelInvitation(props.row)"
            >
              <q-tooltip>Cancel Invitation</q-tooltip>
            </q-btn>
            <span v-else class="text-caption text-grey-5">N/A</span>
          </q-td>
        </template>
      </q-table>
    </q-card>

    <!-- Confirm Cancel Invitation Dialog -->
    <q-dialog v-model="showConfirmCancelInvite" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="warning" color="red-9" text-color="white" class="q-mr-md" />
          <span class="text-h6 text-bold text-slate-800">Cancel Invitation?</span>
        </q-card-section>

        <q-card-section class="q-py-md text-slate-600">
          Are you sure you want to cancel the invitation for
          <span class="text-weight-bold text-slate-800">{{ selectedInvitation?.email }}</span
          >? This token will be immediately invalidated.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" v-close-popup color="grey-7" />
          <q-btn
            flat
            label="Confirm Cancel"
            color="negative"
            @click="handleCancelInvitation"
            :loading="cancellingInvite"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Invite Member Dialog -->
    <q-dialog v-model="showInviteDialog" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md dialog-card">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-slate-800">Invite New Member</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="handleInvite" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Email Address</label
              >
              <q-input
                v-model="inviteEmail"
                type="email"
                filled
                placeholder="collaborator@company.com"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || 'Email is required']"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Role Assignment</label
              >
              <q-select
                v-model="inviteRole"
                :options="rolesOptions"
                filled
                color="primary"
                class="custom-input"
                emit-value
                map-options
              />
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn flat label="Cancel" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              color="primary"
              label="Send Invitation"
              class="q-px-md rounded-btn btn-gradient text-weight-bold"
              :loading="submittingInvite"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Confirm Remove Dialog -->
    <q-dialog v-model="showConfirmRemove" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="warning" color="red-9" text-color="white" class="q-mr-md" />
          <span class="text-h6 text-bold text-slate-800">Remove Team Member?</span>
        </q-card-section>

        <q-card-section class="q-py-md text-slate-600">
          Are you sure you want to remove
          <span class="text-weight-bold text-slate-800">{{
            selectedMember?.user_profile?.full_name || 'this member'
          }}</span>
          from this workspace? This action will immediately revoke their access to all tenant-scoped
          resources.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" v-close-popup color="grey-7" />
          <q-btn
            flat
            label="Confirm Remove"
            color="negative"
            @click="handleRemove"
            :loading="removingMember"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import {
  getTenantMembers,
  getTenantRoles,
  inviteUser,
  removeMember,
  getTenantInvitations,
  cancelInvitation,
} from '../../services/multiTenant';

export interface MemberWithProfile {
  id: string;
  status: string;
  joined_at: string;
  user_id: string;
  tenant_roles: {
    id: string;
    name: string;
    description: string | null;
  } | null;
  user_profile: {
    id: string;
    full_name: string;
    avatar_url: string | null;
  } | null;
}

const tenantStore = useTenantStore();

const members = ref<MemberWithProfile[]>([]);
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const roles = ref<any[]>([]);
const loadingMembers = ref(false);

const errorMsg = ref('');
const successMsg = ref('');

const showInviteDialog = ref(false);
const inviteEmail = ref('');
const inviteRole = ref('');
const submittingInvite = ref(false);

const showConfirmRemove = ref(false);
const selectedMember = ref<MemberWithProfile | null>(null);
const removingMember = ref(false);

// Pending invitations state
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const invitations = ref<any[]>([]);
const loadingInvitations = ref(false);
const cancellingInvite = ref(false);
const showConfirmCancelInvite = ref(false);
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const selectedInvitation = ref<any>(null);

const columns = [
  {
    name: 'user',
    align: 'left' as const,
    label: 'Name / ID',
    field: 'user_profile',
    sortable: true,
  },
  { name: 'role', align: 'left' as const, label: 'Role', field: 'tenant_roles', sortable: true },
  { name: 'status', align: 'left' as const, label: 'Status', field: 'status', sortable: true },
  { name: 'actions', align: 'right' as const, label: 'Actions', field: 'actions' },
];

const invitationsColumns = [
  { name: 'email', align: 'left' as const, label: 'Email Address', field: 'email', sortable: true },
  { name: 'role', align: 'left' as const, label: 'Role', field: 'tenant_roles', sortable: true },
  { name: 'status', align: 'left' as const, label: 'Status', field: 'status', sortable: true },
  {
    name: 'expires_at',
    align: 'left' as const,
    label: 'Expires At',
    field: 'expires_at',
    sortable: true,
  },
  { name: 'actions', align: 'right' as const, label: 'Actions', field: 'actions' },
];

const canManage = computed(() => {
  return (
    tenantStore.activeRole === 'Owner' ||
    tenantStore.activeRole === 'Admin' ||
    tenantStore.isSuperadmin
  );
});

const rolesOptions = computed(() => {
  return roles.value.map((r) => ({
    label: `${r.name} - ${r.description || ''}`,
    value: r.id,
  }));
});

const getInitials = (name: string) => {
  if (!name) return 'MB';
  return name
    .split(' ')
    .map((word) => word[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();
};

const loadMembers = async () => {
  if (!tenantStore.activeTenant) return;
  loadingMembers.value = true;
  errorMsg.value = '';
  try {
    const list = await getTenantMembers(tenantStore.activeTenant.id);
    members.value = (list || []) as unknown as MemberWithProfile[];
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to load workspace members.';
  } finally {
    loadingMembers.value = false;
  }
};

const loadRoles = async () => {
  if (!tenantStore.activeTenant) return;
  try {
    const list = await getTenantRoles(tenantStore.activeTenant.id);
    roles.value = list || [];
    if (list && list.length > 0) {
      // Find Member role to select as default, or select first
      const memberRole = list.find((r) => r.name === 'Member') || list[0];
      inviteRole.value = memberRole.id;
    }
  } catch (err) {
    console.error('Failed to load roles:', err);
  }
};

const handleInvite = async () => {
  if (!tenantStore.activeTenant) return;
  submittingInvite.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await inviteUser(tenantStore.activeTenant.id, inviteEmail.value, inviteRole.value);
    successMsg.value = `Successfully invited ${inviteEmail.value} to this workspace!`;
    showInviteDialog.value = false;
    inviteEmail.value = '';
    await loadInvitations();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to send invitation.';
  } finally {
    submittingInvite.value = false;
  }
};

const confirmRemove = (member: MemberWithProfile) => {
  selectedMember.value = member;
  showConfirmRemove.value = true;
};

const handleRemove = async () => {
  if (!tenantStore.activeTenant || !selectedMember.value) return;
  removingMember.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await removeMember(tenantStore.activeTenant.id, selectedMember.value.user_id);
    successMsg.value = `Successfully removed ${selectedMember.value.user_profile?.full_name || 'member'} from this workspace.`;
    showConfirmRemove.value = false;
    selectedMember.value = null;
    await loadMembers();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to remove member.';
    showConfirmRemove.value = false;
  } finally {
    removingMember.value = false;
  }
};

const loadInvitations = async () => {
  if (!tenantStore.activeTenant) return;
  loadingInvitations.value = true;
  try {
    const list = await getTenantInvitations(tenantStore.activeTenant.id);
    invitations.value = list || [];
  } catch (err) {
    const error = err as Error;
    console.error('Failed to load pending invitations:', error.message);
  } finally {
    loadingInvitations.value = false;
  }
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const confirmCancelInvitation = (invite: any) => {
  selectedInvitation.value = invite;
  showConfirmCancelInvite.value = true;
};

const handleCancelInvitation = async () => {
  if (!tenantStore.activeTenant || !selectedInvitation.value) return;
  cancellingInvite.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await cancelInvitation(tenantStore.activeTenant.id, selectedInvitation.value.id);
    successMsg.value = `Successfully cancelled invitation for ${selectedInvitation.value.email}.`;
    showConfirmCancelInvite.value = false;
    selectedInvitation.value = null;
    await loadInvitations();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to cancel invitation.';
    showConfirmCancelInvite.value = false;
  } finally {
    cancellingInvite.value = false;
  }
};

const formatDate = (dateStr: string) => {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

onMounted(() => {
  void loadMembers();
  void loadRoles();
  void loadInvitations();
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

.member-table-avatar {
  background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
  color: white;
  font-weight: 700;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.dialog-card {
  width: 100%;
  max-width: 500px;
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

.bg-slate-950 {
  background-color: #ffffff !important;
}
</style>
