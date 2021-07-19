version_gt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; 
}

is_semver(){
	if [[ $1 =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]; then
		return 0
	else
		return 1
	fi
}

is_version_downgrade(){
	local CURRENT_VERSION=$1
	local TARGET_VERSION=$2

	# can't reliably compare
	if ! is_semver $TARGET_VERSION || ! is_semver $CURRENT_VERSION; then
		return 1
	fi
	# equal, not a downgrade
	if [[ $TARGET_VERSION == $CURRENT_VERSION ]]; then
		return 1
	fi
	if version_gt $CURRENT_VERSION $TARGET_VERSION; then
		return 0
	else
		return 1
	fi

}