#!/bin/bash
# Apply ReSukiSU manual hooks and kernel compatibility fixes
set -e

echo "[-] Applying ReSukiSU manual hooks..."

# fs/exec.c: ksu_handle_execveat
sed -i '/^int do_execve(struct filename \*filename,$/i#ifdef CONFIG_KSU_MANUAL_HOOK\n__attribute__((hot))\nextern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv, void *envp, int *flags);\n#endif' fs/exec.c
sed -i '/return do_execveat_common(AT_FDCWD, filename, argv, envp, 0);/i#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_execveat((int *)AT_FDCWD, \&filename, \&argv, \&envp, 0);\n#endif' fs/exec.c

# fs/open.c: ksu_handle_faccessat
sed -i '/^SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)$/i#ifdef CONFIG_KSU_MANUAL_HOOK\n__attribute__((hot))\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode, int *flags);\n#endif' fs/open.c
sed -i '/return do_faccessat(dfd, filename, mode);/i#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_faccessat(\&dfd, \&filename, \&mode, NULL);\n#endif' fs/open.c

# fs/stat.c: ksu_handle_stat, ksu_handle_newfstat_ret, ksu_handle_fstat64_ret
sed -i '/^#if !defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_SYS_NEWFSTATAT)$/i#ifdef CONFIG_KSU_MANUAL_HOOK\n__attribute__((hot))\nextern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);\nextern void ksu_handle_newfstat_ret(unsigned int *fd, struct stat __user **statbuf_ptr);\n#if defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_COMPAT_STAT64)\nextern void ksu_handle_fstat64_ret(unsigned long *fd, struct stat64 __user **statbuf_ptr);\n#endif\n#endif' fs/stat.c
sed -i '/error = vfs_fstatat(dfd, \&filename, \&stat, flag);/i#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_stat(\&dfd, \&filename, \&flag);\n#endif' fs/stat.c
sed -i '/error = cp_new_stat(\&stat, \&statbuf);/a#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_newfstat_ret(\&fd, \&statbuf);\n#endif' fs/stat.c
sed -i '/error = cp_new_stat64(\&stat, \&statbuf);/a#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_fstat64_ret(\&fd, \&statbuf);\n#endif' fs/stat.c

# kernel/reboot.c: ksu_handle_sys_reboot
sed -i '/^SYSCALL_DEFINE4(reboot, int, magic1, int, magic2, unsigned int, cmd,$/i#ifdef CONFIG_KSU_MANUAL_HOOK\nextern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);\n#endif' kernel/reboot.c
sed -i '/^	\/\* We only trust the superuser with rebooting the system. \*\//i#ifdef CONFIG_KSU_MANUAL_HOOK\n\tksu_handle_sys_reboot(magic1, magic2, cmd, \&arg);\n#endif' kernel/reboot.c

# Static symbol exports
sed -i 's/^static ssize_t (\*write_op\[\])(/ssize_t (*write_op[])(/' security/selinux/selinuxfs.c
sed -i 's/^static const struct file_operations sel_handle_status_ops =/const struct file_operations sel_handle_status_ops =/' security/selinux/selinuxfs.c
sed -i 's/^static DEFINE_MUTEX(sel_mutex);/DEFINE_MUTEX(sel_mutex);/' security/selinux/selinuxfs.c
sed -i 's/^static DEFINE_RWLOCK(policy_rwlock);/DEFINE_RWLOCK(policy_rwlock);/' security/selinux/ss/services.c

# Include path fixes
sed -i 's|ccflags-y := -Iinclude/linux|ccflags-y := -Iinclude/linux -I$(srctree)/drivers/gpu/msm|' drivers/gpu/msm/Makefile
sed -i '/ccflags-y += -D__CHECK_ENDIAN__/accflags-y += -I$(srctree)/drivers/bluetooth' drivers/bluetooth/Makefile
sed -i '/^ccflags-y += -Idrivers\/media\/platform\/msm\/camera_v2\/$/accflags-y += -I$(srctree)/drivers/media/platform/msm/camera_v2/common' drivers/media/platform/msm/camera_v2/common/Makefile
sed -i '/^ccflags-y += -Idrivers\/media\/platform\/msm\/camera_v2$/accflags-y += -I$(srctree)/drivers/media/platform/msm/camera_v2/isp' drivers/media/platform/msm/camera_v2/isp/Makefile
sed -i '/^ccflags-y += -Idrivers\/media\/platform\/msm\/camera_v2\/sensor$/accflags-y += -I$(srctree)/drivers/media/platform/msm/camera_v2/sensor/io' drivers/media/platform/msm/camera_v2/sensor/io/Makefile
sed -i '/^obj-\$(CONFIG_RNDIS_IPA) += rndis_ipa.o$/i\ccflags-y += -I$(srctree)/drivers/platform/msm/ipa/ipa_clients' drivers/platform/msm/ipa/ipa_clients/Makefile
sed -i '/^obj-\$(CONFIG_IPA) += ipat.o$/i\ccflags-y += -I$(srctree)/drivers/platform/msm/ipa/ipa_v2' drivers/platform/msm/ipa/ipa_v2/Makefile
sed -i '/^ccflags-y.*+= -I\$(srctree)\/drivers\/usb\/gadget\/udc$/s/$/ -I$(srctree)\/drivers\/usb\/gadget/' drivers/usb/gadget/Makefile

# drivers/kernelsu/policy/allowlist.c: remove override_creds(ksu_cred) in save (ENOKEY fix)
sed -i '/^    const struct cred \*saved = override_creds(ksu_cred);$/d' drivers/kernelsu/policy/allowlist.c
sed -i '/^        revert_creds(saved);$/d' drivers/kernelsu/policy/allowlist.c
sed -i '/^    revert_creds(saved);$/d' drivers/kernelsu/policy/allowlist.c

echo "[-] All patches applied successfully."