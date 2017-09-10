Run a variant of the DotCode test for a give range, partitioned accross available processors.


Usage:

./run_test.sh <low_end> <high_end> <field_width> <test_PS_procedure>


Example:

Encode all six-digit numbers with the dotcode_always_light_six.ps test procedure.

./run_test.sh 0 999999 6 dotcode_always_light_six.ps

