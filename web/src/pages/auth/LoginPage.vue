<template>
  <div class="login-container">
    <div class="text-h5 text-bold text-slate-800 q-mb-md">Welcome Back</div>
    <p class="text-slate-500 q-mb-lg text-sm">Enter your credentials to access your workspaces.</p>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <q-form @submit.prevent="handleLogin" class="q-gutter-y-md">
      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >Email Address</label
        >
        <q-input
          v-model="email"
          type="email"
          filled
          placeholder="name@company.com"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || 'Email is required']"
          hide-bottom-space
        />
      </div>

      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >Password</label
        >
        <q-input
          v-model="password"
          type="password"
          filled
          placeholder="••••••••"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || 'Password is required']"
          hide-bottom-space
        />
      </div>

      <q-btn
        type="submit"
        color="primary"
        class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
        label="Sign In"
        :loading="loading"
      />
    </q-form>

    <!-- Separator -->
    <div class="row items-center q-my-lg">
      <q-separator class="col" />
      <span class="text-slate-400 q-px-sm text-xs text-uppercase text-weight-bold"
        >Or continue with</span
      >
      <q-separator class="col" />
    </div>

    <!-- Google Login Button -->
    <q-btn
      outline
      no-caps
      class="full-width q-py-sm rounded-btn google-btn text-weight-bold"
      :loading="loading"
      @click="handleGoogleLogin"
    >
      <div class="row items-center no-wrap">
        <q-icon
          name="img:https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg"
          size="18px"
          class="q-mr-sm"
        />
        <span>Sign in with Google</span>
      </div>
    </q-btn>

    <div class="q-mt-xl text-center text-sm text-slate-500">
      Don't have an account?
      <router-link to="/auth/signup" class="text-primary text-weight-bold hover-underline">
        Sign Up
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { signInWithEmail, signInWithGoogle } from '../../services/multiTenant';
import { useTenantStore } from '../../stores/tenant';

const router = useRouter();
const route = useRoute();
const tenantStore = useTenantStore();

const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');

const handleLogin = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    const { error } = await signInWithEmail(email.value, password.value);
    if (error) {
      errorMsg.value = error.message;
      return;
    }

    // Success, reinitialize the store to load profiles & memberships
    await tenantStore.initializeStore();

    // Check where to redirect
    const redirectPath = route.query.redirect as string | undefined;
    if (redirectPath) {
      await router.push(redirectPath);
      return;
    }

    if (tenantStore.isSuperadmin) {
      await router.push('/admin/dashboard');
    } else if (tenantStore.myTenants.length > 0 && tenantStore.myTenants[0]?.tenants) {
      // Go to first tenant workspace dashboard
      await router.push(`/${tenantStore.myTenants[0]?.tenants?.slug}/dashboard`);
    } else {
      await router.push('/auth/no-tenant');
    }
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'An unexpected error occurred';
  } finally {
    loading.value = false;
  }
};

const handleGoogleLogin = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    const redirectPath = route.query.redirect as string | undefined;
    const redirectTo = redirectPath ? window.location.origin + redirectPath : undefined;
    const { error } = await signInWithGoogle(redirectTo);
    if (error) {
      errorMsg.value = error.message;
    }
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'An unexpected error occurred';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
.login-container {
  width: 100%;
}

.input-label {
  display: block;
}

.block {
  display: block;
}

.rounded-btn {
  border-radius: 12px;
}

.btn-gradient {
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
  border: none;

  &:hover {
    filter: brightness(1.1);
  }
}

.google-btn {
  background: #ffffff !important;
  border: 1px solid #cbd5e1 !important;
  color: #0f172a !important;
  transition: all 0.2s ease-in-out;

  &:hover {
    background: #f8fafc !important;
    border-color: #94a3b8 !important;
  }
}

.hover-underline:hover {
  text-decoration: underline;
}

.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #ffffff !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;

  &:hover {
    border-color: #94a3b8;
  }

  &.q-field__control--focused {
    border-color: #6366f1;
    box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15);
  }
}
</style>
