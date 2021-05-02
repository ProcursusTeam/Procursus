$NetBSD: patch-lib_libpam_openpam__constants.c,v 1.2 2018/05/15 07:57:32 triaxx Exp $

Change hardcoded configuration paths to ones depending on compiler variables.
Fix OPENPAM_MODULES_DIR to avoid openpam loading basesystem modules.

--- lib/libpam/openpam_constants.c.orig	2017-04-30 21:34:49.000000000 +0000
+++ lib/libpam/openpam_constants.c
@@ -167,16 +167,14 @@ const char *pam_sm_func_name[PAM_NUM_PRI
 };
 
 const char *openpam_policy_path[] = {
-	"/etc/pam.d/",
-	"/etc/pam.conf",
-	"/usr/local/etc/pam.d/",
-	"/usr/local/etc/pam.conf",
+	SYSCONFDIR "/pam.d/",
+	SYSCONFDIR "/pam.conf",
 	NULL
 };
 
 const char *openpam_module_path[] = {
-#ifdef OPENPAM_MODULES_DIRECTORY
-	OPENPAM_MODULES_DIRECTORY,
+#ifdef OPENPAM_MODULES_DIR
+	OPENPAM_MODULES_DIR,
 #else
 	"/usr/lib",
 	"/usr/local/lib",
