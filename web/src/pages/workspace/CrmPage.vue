<template>
  <q-page class="q-pa-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-xl">
      <div>
        <h1 class="text-h4 text-bold q-my-none flex items-center text-slate-850">
          <q-icon name="stars" color="indigo-8" size="36px" class="q-mr-sm" />
          CRM Workspace
        </h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Manage your pipeline, contacts, and opportunities for
          <span class="text-indigo-8 text-weight-bold">{{ tenantStore.activeTenant?.name }}</span>
        </p>
      </div>
      <div>
        <q-btn
          color="indigo-7"
          icon="add"
          label="New Opportunity"
          no-caps
          class="rounded-borders-lg q-px-md font-semibold text-weight-bold"
          @click="showAddDealDialog = true"
        />
      </div>
    </div>

    <!-- Overview Metrics Cards -->
    <div class="row q-col-gutter-lg q-mb-lg">
      <div class="col-12 col-sm-6 col-md-3" v-for="metric in metrics" :key="metric.label">
        <q-card class="glass-card">
          <q-card-section class="q-pa-md flex justify-between items-center">
            <div>
              <div class="text-slate-500 text-xs text-weight-bold uppercase tracking-wider q-mb-xs">
                {{ metric.label }}
              </div>
              <div class="text-h5 text-bold text-slate-800">{{ metric.value }}</div>
            </div>
            <q-avatar :color="metric.avatarBg" size="42px" class="text-white">
              <q-icon :name="metric.icon" size="24px" :class="metric.iconColor" />
            </q-avatar>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <div class="row q-col-gutter-lg">
      <!-- Pipeline Stages Progress -->
      <div class="col-12 col-lg-5">
        <q-card class="glass-card full-height">
          <q-card-section class="card-gradient-header row items-center q-pb-md">
            <q-icon name="trending_up" size="24px" class="text-indigo-8 q-mr-sm" />
            <div class="text-h6 text-bold text-slate-800">Pipeline Stage Conversion</div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div v-for="stage in pipelineStages" :key="stage.name" class="q-mb-md">
              <div class="row justify-between text-xs font-semibold q-mb-xs text-slate-700">
                <span>{{ stage.name }}</span>
                <span class="text-slate-500">{{ stage.count }} deals ({{ stage.value }})</span>
              </div>
              <q-linear-progress
                :value="stage.percentage"
                color="indigo-8"
                track-color="grey-3"
                class="rounded-borders"
                size="8px"
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Recent Opportunities Table/List -->
      <div class="col-12 col-lg-7">
        <q-card class="glass-card full-height">
          <q-card-section class="card-gradient-header row items-center justify-between q-pb-md">
            <div class="row items-center">
              <q-icon name="list_alt" size="24px" class="text-cyan-8 q-mr-sm" />
              <div class="text-h6 text-bold text-slate-800">Recent Opportunities</div>
            </div>
            <q-chip outline color="cyan-8" size="sm">Active Leads</q-chip>
          </q-card-section>

          <q-card-section class="q-pa-none">
            <q-list separator class="text-slate-800">
              <q-item v-for="deal in deals" :key="deal.id" class="q-py-md hover-row">
                <q-item-section avatar>
                  <q-avatar color="indigo-1" text-color="indigo-9" class="font-semibold">
                    {{ deal.client.substring(0, 2).toUpperCase() }}
                  </q-avatar>
                </q-item-section>

                <q-item-section>
                  <q-item-label class="text-weight-bold text-slate-800">{{
                    deal.title
                  }}</q-item-label>
                  <q-item-label caption class="text-slate-500">
                    {{ deal.client }} &bull; Updated {{ deal.updatedAt }}
                  </q-item-label>
                </q-item-section>

                <q-item-section side>
                  <div class="text-right">
                    <div class="text-weight-bold text-slate-800">{{ deal.amount }}</div>
                    <q-badge
                      :color="getStatusColor(deal.status)"
                      class="text-weight-bold text-black text-xs uppercase q-mt-xs"
                    >
                      {{ deal.status }}
                    </q-badge>
                  </div>
                </q-item-section>
              </q-item>
            </q-list>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Create Opportunity Mock Dialog -->
    <q-dialog v-model="showAddDealDialog">
      <q-card
        class="glass-dialog text-slate-800 q-pa-md"
        style="min-width: 400px; background-color: #ffffff"
      >
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-slate-800">Create New Opportunity</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup class="text-slate-500" />
        </q-card-section>

        <q-card-section class="q-pt-md">
          <q-input filled v-model="newDeal.title" label="Deal / Opportunity Name" class="q-mb-md" />
          <q-input filled v-model="newDeal.client" label="Client Organization" class="q-mb-md" />
          <q-input
            filled
            v-model="newDeal.amount"
            label="Estimated Deal Value ($)"
            type="number"
            class="q-mb-md"
          />
          <q-select
            filled
            v-model="newDeal.status"
            :options="['Lead', 'Contacted', 'Proposal', 'Negotiating', 'Won', 'Lost']"
            label="Pipeline Stage"
          />
        </q-card-section>

        <q-card-actions align="right" class="q-pt-md">
          <q-btn flat label="Cancel" no-caps v-close-popup class="text-slate-500" />
          <q-btn
            color="indigo-7"
            label="Add Deal"
            no-caps
            @click="handleAddDeal"
            class="font-semibold"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import { useQuasar } from 'quasar';

const tenantStore = useTenantStore();
const $q = useQuasar();

const showAddDealDialog = ref(false);
const newDeal = ref({
  title: '',
  client: '',
  amount: '',
  status: 'Lead',
});

const metrics = computed(() => [
  {
    label: 'Total Pipeline',
    value: '$248,500',
    icon: 'payments',
    avatarBg: 'indigo-10',
    iconColor: 'text-indigo-3',
  },
  {
    label: 'Deals Count',
    value: '18 Active',
    icon: 'pie_chart',
    avatarBg: 'cyan-10',
    iconColor: 'text-cyan-3',
  },
  {
    label: 'Conversion Rate',
    value: '64.2%',
    icon: 'bolt',
    avatarBg: 'amber-10',
    iconColor: 'text-amber-3',
  },
  {
    label: 'Avg Deal Size',
    value: '$13,805',
    icon: 'analytics',
    avatarBg: 'purple-10',
    iconColor: 'text-purple-3',
  },
]);

const pipelineStages = ref([
  { name: 'Lead Qualification', count: 6, value: '$45,000', percentage: 0.8 },
  { name: 'Meeting Scheduled', count: 4, value: '$56,000', percentage: 0.6 },
  { name: 'Proposal Sent', count: 5, value: '$92,500', percentage: 0.75 },
  { name: 'Contract Review', count: 3, value: '$55,000', percentage: 0.45 },
]);

const deals = ref([
  {
    id: '1',
    title: 'Enterprise Hub Integration',
    client: 'Starlight Corp',
    status: 'proposal',
    amount: '$74,000',
    updatedAt: '2 hours ago',
  },
  {
    id: '2',
    title: 'E-Commerce Redesign Contract',
    client: 'Apex Ltd',
    status: 'negotiating',
    amount: '$38,500',
    updatedAt: '1 day ago',
  },
  {
    id: '3',
    title: 'Consulting Retainer Q3',
    client: 'Nexa Group',
    status: 'won',
    amount: '$15,000',
    updatedAt: '2 days ago',
  },
  {
    id: '4',
    title: 'SaaS Platform Provisioning',
    client: 'Zenith Labs',
    status: 'lead',
    amount: '$120,000',
    updatedAt: '3 days ago',
  },
  {
    id: '5',
    title: 'Mobile Client UI Port',
    client: 'Skyline LLC',
    status: 'lost',
    amount: '$21,000',
    updatedAt: '1 week ago',
  },
]);

const getStatusColor = (status: string) => {
  switch (status.toLowerCase()) {
    case 'won':
      return 'positive';
    case 'lost':
      return 'negative';
    case 'negotiating':
      return 'amber';
    case 'proposal':
      return 'cyan';
    default:
      return 'indigo-3';
  }
};

const handleAddDeal = () => {
  if (!newDeal.value.title || !newDeal.value.client || !newDeal.value.amount) {
    $q.notify({ type: 'warning', message: 'Please fill in all fields' });
    return;
  }

  const val = parseFloat(newDeal.value.amount);
  const formattedVal = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(val);

  deals.value.unshift({
    id: String(deals.value.length + 1),
    title: newDeal.value.title,
    client: newDeal.value.client,
    status: newDeal.value.status.toLowerCase(),
    amount: formattedVal,
    updatedAt: 'Just now',
  });

  showAddDealDialog.value = false;
  newDeal.value = { title: '', client: '', amount: '', status: 'Lead' };

  $q.notify({
    type: 'positive',
    message: 'Opportunity successfully added to pipeline!',
    position: 'top',
  });
};
</script>

<style scoped lang="scss">
.glass-card {
  background: #ffffff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
  overflow: hidden;
}

.card-gradient-header {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  background: #ffffff;
}

.hover-row {
  transition: background-color 0.2s ease;
  &:hover {
    background-color: #f1f5f9;
  }
}

.rounded-borders-lg {
  border-radius: 10px;
}

.tracking-wider {
  letter-spacing: 0.05em;
}
</style>
