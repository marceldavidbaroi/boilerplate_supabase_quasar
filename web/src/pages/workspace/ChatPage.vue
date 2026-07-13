<template>
  <q-page class="q-pa-lg flex flex-col no-scroll-page">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-md flex-shrink-0">
      <div>
        <h1 class="text-h4 text-bold q-my-none flex items-center text-slate-850">
          <q-icon name="chat" color="purple-6" size="36px" class="q-mr-sm" />
          Team Chat
        </h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Real-time collaborative channels for
          <span class="text-purple-6 text-weight-bold">{{ tenantStore.activeTenant?.name }}</span>
        </p>
      </div>
    </div>

    <!-- Chat Container -->
    <div
      class="row chat-layout-container border-all rounded-borders-lg overflow-hidden flex-grow-1"
    >
      <!-- Channels Sidebar -->
      <div class="col-12 col-sm-4 bg-slate-950 border-right flex flex-col sidebar-height">
        <!-- Workspace title -->
        <div class="q-pa-md border-bottom flex items-center">
          <q-avatar size="24px" class="bg-purple-9 q-mr-sm text-xs font-bold text-white">
            {{ tenantStore.activeTenant?.name.substring(0, 1).toUpperCase() }}
          </q-avatar>
          <div class="text-subtitle2 text-weight-bold truncate-text text-slate-800">
            {{ tenantStore.activeTenant?.name }} Rooms
          </div>
        </div>

        <!-- Scrollable lists -->
        <div class="flex-grow-1 overflow-auto q-py-sm">
          <!-- Channels -->
          <div class="q-mb-md">
            <div
              class="q-px-md text-xxs text-slate-500 font-semibold uppercase tracking-wider q-mb-xs flex items-center justify-between"
            >
              <span>Channels</span>
              <q-btn flat round dense size="xs" icon="add" color="grey-7" @click="mockAddChannel" />
            </div>
            <q-list dense>
              <q-item
                v-for="ch in channels"
                :key="ch.name"
                clickable
                :active="activeRoom === ch.name"
                active-class="active-room-item"
                class="room-item q-mx-sm rounded-borders q-py-xs"
                @click="selectRoom(ch.name, true)"
              >
                <q-item-section avatar class="min-w-0 q-pr-sm">
                  <span class="text-slate-500 text-weight-bold text-subtitle1">#</span>
                </q-item-section>
                <q-item-section class="text-weight-medium text-xs text-slate-700">{{
                  ch.name
                }}</q-item-section>
                <q-item-section side v-if="ch.unread">
                  <q-badge color="purple-5" rounded />
                </q-item-section>
              </q-item>
            </q-list>
          </div>

          <!-- Direct Messages -->
          <div>
            <div
              class="q-px-md text-xxs text-slate-500 font-semibold uppercase tracking-wider q-mb-xs"
            >
              Direct Messages
            </div>
            <q-list dense>
              <q-item
                v-for="dm in directMessages"
                :key="dm.name"
                clickable
                :active="activeRoom === dm.name"
                active-class="active-room-item"
                class="room-item q-mx-sm rounded-borders q-py-xs"
                @click="selectRoom(dm.name, false)"
              >
                <q-item-section avatar class="min-w-0 q-pr-sm">
                  <q-avatar
                    size="18px"
                    :color="dm.avatarBg"
                    class="text-white text-xxs text-weight-bold"
                  >
                    {{ dm.name.substring(0, 1) }}
                  </q-avatar>
                </q-item-section>
                <q-item-section class="text-weight-medium text-xs text-slate-700">
                  {{ dm.name }}
                  <span v-if="dm.isMe" class="text-slate-400 text-xxs font-normal">(You)</span>
                </q-item-section>
                <q-item-section side>
                  <q-badge
                    rounded
                    :color="dm.online ? 'positive' : 'grey-5'"
                    size="8px"
                    class="status-dot"
                  />
                </q-item-section>
              </q-item>
            </q-list>
          </div>
        </div>
      </div>

      <!-- Messages Stream Panel -->
      <div class="col-12 col-sm-8 bg-slate-900 flex flex-col stream-height">
        <!-- Room Header -->
        <div
          class="q-pa-md border-bottom bg-slate-950 flex-shrink-0 flex items-center justify-between"
        >
          <div>
            <div class="text-subtitle2 text-weight-bold flex items-center text-slate-800">
              <span class="text-slate-500 q-mr-xs text-h6 leading-none" v-if="isChannel">#</span>
              {{ activeRoom }}
            </div>
            <div class="text-xxs text-slate-500 q-mt-xs">
              {{ activeRoomDesc }}
            </div>
          </div>
          <q-btn flat round dense size="sm" icon="info" color="grey-7" @click="mockRoomInfo" />
        </div>

        <!-- Chat Stream (Scrollable) -->
        <div class="flex-grow-1 overflow-auto q-pa-md messages-stream" ref="streamContainer">
          <div v-for="(msg, index) in activeMessages" :key="index" class="q-mb-md flex items-start">
            <q-avatar
              size="32px"
              :color="msg.avatarBg"
              class="text-white text-weight-bold q-mr-sm flex-shrink-0"
            >
              {{ msg.sender.substring(0, 1).toUpperCase() }}
            </q-avatar>
            <div class="message-bubble-wrapper">
              <div class="flex items-baseline q-mb-xxs">
                <span class="text-weight-bold text-xs text-slate-800 q-mr-sm">{{
                  msg.sender
                }}</span>
                <span class="text-xxs text-slate-400">{{ msg.time }}</span>
              </div>
              <div class="message-content text-xs text-slate-700 q-py-sm q-px-md glass-bubble">
                {{ msg.text }}
              </div>
            </div>
          </div>
        </div>

        <!-- Message Input Bar -->
        <div class="q-pa-md border-top bg-slate-950 flex-shrink-0">
          <q-form @submit.prevent="sendMessage" class="row items-center q-col-gutter-sm">
            <div class="col">
              <q-input
                dense
                standout
                v-model="messageText"
                placeholder="Type your message here..."
                class="message-input"
                autocomplete="off"
              />
            </div>
            <div class="col-auto">
              <q-btn
                round
                color="purple-6"
                icon="send"
                type="submit"
                dense
                class="q-px-sm"
                :disable="!messageText.trim()"
              />
            </div>
          </q-form>
        </div>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, nextTick, onMounted } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import { useQuasar } from 'quasar';

const tenantStore = useTenantStore();
const $q = useQuasar();

const activeRoom = ref('general');
const isChannel = ref(true);
const messageText = ref('');
const streamContainer = ref<HTMLElement | null>(null);

const channels = ref([
  { name: 'general', desc: 'Company-wide general chat and news.', unread: false },
  { name: 'marketing', desc: 'Campaign strategies, designs, and content updates.', unread: true },
  { name: 'development', desc: 'Git commits, dev talk, and system status.', unread: false },
  {
    name: 'billing-alerts',
    desc: 'Subscription notifications and invoice triggers.',
    unread: false,
  },
]);

const directMessages = ref([
  { name: 'Marcel David', avatarBg: 'indigo-8', online: true, isMe: false },
  { name: 'David (You)', avatarBg: 'teal-8', online: true, isMe: true },
  { name: 'Supabase System Bot', avatarBg: 'emerald-9', online: false, isMe: false },
]);

// Mock message database mapping rooms to messages
const messageLogs = ref<
  Record<string, Array<{ sender: string; time: string; text: string; avatarBg: string }>>
>({
  general: [
    {
      sender: 'Marcel David',
      time: '10:15 AM',
      text: 'Hey team, did we deploy the new database migrations for multi-tenant isolation?',
      avatarBg: 'indigo-8',
    },
    {
      sender: 'Supabase System Bot',
      time: '10:16 AM',
      text: 'Migration 20260713000001_init_phase2 executed successfully. Stored procedures compiled.',
      avatarBg: 'emerald-9',
    },
    {
      sender: 'David (You)',
      time: '10:20 AM',
      text: 'Yes Marcel! Phase 2 is online, and today we are implementing Phase 4 store/routing integrations.',
      avatarBg: 'teal-8',
    },
  ],
  marketing: [
    {
      sender: 'Marcel David',
      time: 'Yesterday',
      text: 'Check out the new branding dashboard. The colors need to match the active workspace settings dynamically.',
      avatarBg: 'indigo-8',
    },
  ],
  development: [
    {
      sender: 'Supabase System Bot',
      time: '9:00 AM',
      text: 'Warning: CPU usage on local database docker container hit 82% during seeding.',
      avatarBg: 'emerald-9',
    },
    {
      sender: 'David (You)',
      time: '9:05 AM',
      text: 'Thanks. Optimizing index configurations inside migration scripts.',
      avatarBg: 'teal-8',
    },
  ],
  'billing-alerts': [
    {
      sender: 'Supabase System Bot',
      time: 'Monday',
      text: 'Tenant "Quantum Labs" billing status changed from suspended to active (tier: premium).',
      avatarBg: 'emerald-9',
    },
  ],
  'Marcel David': [
    {
      sender: 'Marcel David',
      time: '11:00 AM',
      text: 'Hey, let me know if you need help with the route guards testing.',
      avatarBg: 'indigo-8',
    },
    {
      sender: 'David (You)',
      time: '11:02 AM',
      text: 'Thanks, I have configured it to inspect activeSettings and redirect gracefully.',
      avatarBg: 'teal-8',
    },
  ],
  'Supabase System Bot': [
    {
      sender: 'Supabase System Bot',
      time: 'Yesterday',
      text: 'I am a automated notification assistant. I post database events and webhook triggers.',
      avatarBg: 'emerald-9',
    },
  ],
});

const activeMessages = computed(() => {
  return messageLogs.value[activeRoom.value] || [];
});

const activeRoomDesc = computed(() => {
  if (isChannel.value) {
    return channels.value.find((c) => c.name === activeRoom.value)?.desc || 'Discussion room';
  } else {
    const user = directMessages.value.find((d) => d.name === activeRoom.value);
    return user
      ? `${user.name} is currently ${user.online ? 'Online' : 'Offline'}`
      : 'Private conversation';
  }
});

const selectRoom = (name: string, channelType: boolean) => {
  activeRoom.value = name;
  isChannel.value = channelType;

  if (channelType) {
    const ch = channels.value.find((c) => c.name === name);
    if (ch) ch.unread = false;
  }

  void nextTick(() => {
    scrollToBottom();
  });
};

const sendMessage = () => {
  if (!messageText.value.trim()) return;

  const now = new Date();
  const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  let logs = messageLogs.value[activeRoom.value];
  if (!logs) {
    logs = [];
    messageLogs.value[activeRoom.value] = logs;
  }

  logs.push({
    sender: 'David (You)',
    time: timeStr,
    text: messageText.value.trim(),
    avatarBg: 'teal-8',
  });

  messageText.value = '';

  void nextTick(() => {
    scrollToBottom();
  });

  // Small bot reply simulator for interactive feel
  if (activeRoom.value === 'Supabase System Bot') {
    setTimeout(() => {
      let botLogs = messageLogs.value['Supabase System Bot'];
      if (!botLogs) {
        botLogs = [];
        messageLogs.value['Supabase System Bot'] = botLogs;
      }
      botLogs.push({
        sender: 'Supabase System Bot',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        text: 'Received manual input. Simulated response processed. Keep up the good work!',
        avatarBg: 'emerald-9',
      });
      void nextTick(() => {
        scrollToBottom();
      });
    }, 1000);
  }
};

const scrollToBottom = () => {
  if (streamContainer.value) {
    streamContainer.value.scrollTop = streamContainer.value.scrollHeight;
  }
};

const mockAddChannel = () => {
  $q.notify({
    type: 'info',
    message: 'Add Room feature is a mock design item.',
    position: 'bottom',
  });
};

const mockRoomInfo = () => {
  $q.dialog({
    title: 'Room Details',
    message: `Room Name: ${activeRoom.value}\nDescription: ${activeRoomDesc.value}`,
    dark: true,
    ok: true,
  });
};

onMounted(() => {
  scrollToBottom();
});
</script>

<style scoped lang="scss">
.no-scroll-page {
  height: calc(100vh - 120px);
  overflow: hidden;
}

.chat-layout-container {
  display: flex;
  background-color: #0b0f19;
  height: 100%;
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.border-right {
  border-right: 1px solid rgba(0, 0, 0, 0.06);
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.sidebar-height {
  height: 100%;
}

.stream-height {
  height: 100%;
}

.rounded-borders-lg {
  border-radius: 12px;
}

.room-item {
  border-radius: 8px;
  color: #475569;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    color: #0f172a;
  }
}

.active-room-item {
  background: rgba(168, 85, 247, 0.08) !important;
  color: #7c3aed !important;
  font-weight: bold;
}

.status-dot {
  padding: 0;
  min-width: 8px;
  height: 8px;
}

.messages-stream {
  background-color: #f8fafc;
}

.glass-bubble {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 4px 16px 16px 16px;
  display: inline-block;
  max-width: 85%;
  word-break: break-word;
  line-height: 1.5;
}

.message-bubble-wrapper {
  max-width: 85%;
}

.message-input {
  :deep(.q-field__control) {
    background-color: #ffffff;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
  }
}

.truncate-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.text-xxs {
  font-size: 10px;
}

.min-w-0 {
  min-width: unset;
}
</style>
