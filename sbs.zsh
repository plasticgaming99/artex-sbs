#!/usr/bin/env zsh

runsu() {
	if [ $UID = 0 ]; then
		return
	fi

	if command -v sudo >/dev/null 2>&1; then
		sudo $@
	elif command -v sudo >/dev/null 2>&1; then
		doas $@
	else
		echo "! No SUDO/DOAS Found! Using su"
		su -c $*
	fi
}

if [ $0 = "clean" ]; then
	runsu rm -fr alpine alpine*.tar.zst
fi

if command -v sudo | echo $?; then
	sudo $chroot_cmd
elif command -v sudo | echo $?; then
	doas $chroot_cmd
else
	echo "! No SUDO/DOAS Found! Using su"
	su -c "$chroot_cmd"
fi

echo ": Building some integra tools"

toolchains=$PWD

if [ ! -d ${PWD}/toolchains ]; then
	echo ': Creating directory "toolchains"'
fi

# Avoid linking to GCC! (why don't build them with alpine)

export CGO_ENABLED=0

pushd buildintegra
	go build
	cp ./buildintegra $toolchains || true
popd

pushd integra
	go build
	cp ./integra $toolchains || true
popd

echo ": Building toolchains finished"

# alpine

echo ": Preparing Alpine"
alpine_version="3.22.0"
alpine_url="https://dl-cdn.alpinelinux.org/alpine/v${${alpine_version}%??}/releases/x86_64/alpine-minirootfs-${alpine_version}-x86_64.tar.gz"
may_alpine=$PWD"/alpine-minirootfs-${alpine_version}-x86_64.tar.gz"

if command -v aria2c | echo $?; then
	aria2c $alpine_url --auto-file-renaming=false
else
	curl -OL $alpine_url
fi

echo ": Extract Alpine"

alpine_dir=$PWD"/alpine"

if [ ! -d "$alpine_dir" ]; then
	mkdir "$alpine_dir"
fi

pushd alpine
	runsu tar -xf "$may_alpine"
popd

chroot_script=$PWD"/sbs_chroot.sh"

if [ ! -f  ]; then
	echo ": Copy Script to Alpine"
	runsu cp $chroot_script $alpine_dir/root/
fi

echo ": Chroot to Alpine"

chroot_cmd_zsh=(chroot alpine /bin/busybox ash -c "apk upgrade; apk add zsh")
runsu $chroot_cmd_zsh

chroot_cmd=(chroot alpine /bin/busybox ash -c /root/sbs_chroot.zsh)

runsu $chroot_cmd

