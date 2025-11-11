debug:
	qrun -64 -gui -visualizer -onfinish stop -classdebug -uvmcontrol=all -msgmode both -l run.log -f filelist.f \
	-do "set IterationLimit 140000; set NoQuitOnFinish 1; run -all; coverage save -onexit cov_test_top.ucdb; do wave.do" \
	+UVM_TESTNAME=test_top -debug,livesim \
	-qwavedb=+signal+memory=1024+report+parameter+class+assertion+uvm_schematic+msg+classmemory=1024+statictaskfunc \
	-top hdl_top -top hvl_top

clean:
	rm design.bin
	rm qwave.db
	rm *.log
	rm -rf qrun.out
	rm -rf .visualizer
