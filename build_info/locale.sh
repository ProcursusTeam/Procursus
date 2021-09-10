SYSTEM_LOCALE=$(deviceinfo locale)
if [ "$SYSTEM_LOCALE" != 'zh_HK' ]; then
	LANG="$SYSTEM_LOCALE"
	LANGUAGE="$SYSTEM_LOCALE".UTF-8
else
	LANG='zh_TW'
	LANG='zh_TW.UTF-8'
fi
export LANG LANGUAGE
