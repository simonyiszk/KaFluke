sources := debounce.v tdr.v
constrains := Cmod-A7-Master.xdc

workdir := ./workdir
builddir := ./build

fasm2frames := python ~/.local/bin/build_stage/prjxray/utils/fasm2frames.py
xray_dbroot := /usr/share/xray/database
openFPGALoader := /usr/bin/openFPGALoader

board := cmoda7_35t
family := artix7
part := xc7a35tcpg236-1
target_freq := 12

synthesize:
	yosys $(sources) -p "synth_xilinx; write_json $(builddir)/tdr.json"

place_and_route: synthesize
	nextpnr-himbaechel --device $(part) --json $(builddir)/tdr.json -o xdc=$(constrains) --write $(builddir)/tdr_routed.json -o fasm=$(builddir)/tdr.fasm --router router2 --freq $(target_freq)

generate_frames: place_and_route
	$(fasm2frames) --db-root $(xray_dbroot)/$(family) --part $(part) $(builddir)/tdr.fasm $(builddir)/tdr.frames

generate_bitstream: generate_frames
	xc7frames2bit --part_file $(xray_dbroot)/$(family)/$(part)/part.yaml --frm_file $(builddir)/tdr.frames --output_file $(builddir)/tdr.bit

program: generate_bitstream
	$(openFPGALoader) -b $(board) $(builddir)/tdr.bit

program_flash: generate_bitstream
	$(openFPGALoader) -b $(board) -f $(builddir)/tdr.bit

main: program

