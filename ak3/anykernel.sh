### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=BakaSU for Xiaomi Redmi 5 (rosy) by wxmyyds
do.devicecheck=1
device.name1=rosy
do.cleanup=1
'; }

BLOCK=/dev/block/bootdevice/by-name/boot;
is_slot_device=auto;
no_block_display=1;

. tools/ak3-core.sh;

split_boot;
flash_boot;
