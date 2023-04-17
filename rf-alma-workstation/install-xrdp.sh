set -eou pipefail

sudo dnf install epel-release -y
sudo dnf install mock -y 

sudo usermod -a -G mock $USER
groups | grep -q mock
if [[ "$?" != "0" ]]; then
    echo "Need to update group permissions, log back in and re-execute this script"
    exit 0
fi

sudo dnf install "@base-x" "@Xfce" xrdp -y
sudo systemctl enable --now xrdp
sudo firewall-cmd --zone=public --add-port 3389/tcp --permanent
sudo dnf config-manager --set-enabled crb


cd ~
mkdir -p xrdp-tmp
cd xrdp-tmp
dnf download --source pulseaudio sbc libatomic_ops webrtc-audio-processing
mock --chain ./sbc-*.src.rpm ./libatomic_ops-*.src.rpm ./webrtc-audio-processing-*.src.rpm ./pulseaudio-*.src.rpm
export PULSE_DIR=$(find /var/lib/mock -type d -name pulseaudio-\* 2>/dev/null | grep -v BUILDROOT)

echo PULSE_DIR=$PULSE_DIR
read -p "Input: " ans 

sudo dnf install autoconf automake make libtool libtool-ltdl-devel pulseaudio-libs-devel git -y
git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
./bootstrap && ./configure PULSE_DIR=$PULSE_DIR
make
sudo make install

sudo dnf install --allowerasing pulseaudio -y
systemctl --user enable --now  pulseaudio.service 

# # Clean up a little at least
# dnf history undo last
# mock --clean
# cd ~
# rm -rf xrdp-tmp