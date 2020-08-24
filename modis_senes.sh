#!/bin/bash


do_run()
{
  echo $*
  if $* ; then
    true
  else
    exit 1
  fi
}

checkpython()
{
  if [ -z "$PYTHONPATH" ]
    then
    export PYTHONPATH=$HOME/lib64/python
  fi
}

dummy()
{
  dummyL=1
  for i in $dummy ; do
    dummyL=`expr $dummyL + 1 `
  done
}

dummy2()
{
  dummyL=1
  if [[ $dummy -eq 1 ]]
  then
    dummyL=`expr $dummyL + 1 `
  fi
}

dummy3()
{
  dummyL=1
  while test $dummy -le $dummyL ; do
    dummyL=`expr $dummyL + 1 `
  done
}

createEmpiricalData()
{
  tp_name=`printf '%s' ${true_model} `
  echo ${tp_name}
  do_run ../transsyswork/modeldiscrimination/trunk/transsyswritesimsetOF -o  ${simgenex_model} -t 1 -s ${rndseed} -N ${signal_to_noise} ${true_model}'.tra' ${tp_name}'.txt' 'trace.txt'
}

optimiseModelEmpiric()
{

  for model in ${gentype_target_list} ;  do
    ../transsyswork/modeldiscrimination/trunk/netopt -x  ${empirical_data} -o ${simgenex_model} -R ${num_optimisations} -g ${gradientfile} -T ${transformerfile} -s ${rndseed} -c ${model} 'opt_'${model}'.txt' 'tp_'${model}'.txt' 'log.txt'
  done
}



generate_target_programs ()
{
  # generate random target topologies
  # note: rndseed for topology generation is in transsysgen files
  for gentype in ${gentype_list} ; do
    #./transsysrandomprogram
    ../transsyswork/modeldiscrimination/trunk/transsysrandomprogram -n target_${gentype} -m ${num_target_topologies} -p paraer.dat
  done
  target_topology_number=1
  while test ${target_topology_number} -le ${num_target_topologies} ; do
    #for 	  
      topology_name=`printf 'target_%s%02d' ${gentype} ${target_topology_number}`
      topology_name_new=`printf '%s_p00_w00_r00' $topology_name  `
      topology_file=${topology_name}.tra
      topology_file_new=${topology_name_new}.tra
      mv $topology_file $topology_file_new
      #model=`printf '%s_p%02d_w%02d_r%02d' ${candidate_topology_basename} ${target_parameterisation_number} $num_rewirings $rewired_topology`
      sed 's/f0000/NAM_A1/g;s/f0001/NAM_A2/g;s/f0002/NAM_D1/g;s/f0003/NAM_D2/g;s/f0004/NAM_B2/g;s/f0005/VRN_B3/g;s/g0000/NAM_A1_gene/g;s/g0001/NAM_A2_gene/g;s/g0002/NAM_D1_gene/g;s/g0003/NAM_D2_gene/g;s/g0004/NAM_B2_gene/g;s/g0005/VRN_B3_gene/g' $topology_file_new > clean.txt
      mv clean.txt $topology_file_new
      #rm -f $candidate_topology_logo'.bk'
      #name=`printf '%s %s ' $name $candidate_topology_logo `
      #rewired_topology_number=`expr ${rewired_topology_number} + 1`
      #tp_basename=${topology_name}_p
      #../transsyswork/modeldiscrimination/trunk/transsysreparam -T ${transformerfile} -s ${rndseed} -p ${num_target_parameterisations} -n ${tp_basename} ${topology_file}
      #rndseed=`expr ${rndseed} + 1`
      target_topology_number=`expr ${target_topology_number} + 1`
     # done
  done
}


optimise_numrewired_cluster ()
{
  for num_rewirings in ${num_rewirings_list} ; do
    scriptname=`printf '%s_w%02d.csh' ${candidate_topology_basename} ${num_rewirings}`
    write_cshscript_header $scriptname
    rewired_topology_number=1
    while test ${rewired_topology_number} -le ${num_rewired_topologies} ; do
      candidate_topology=`printf '%s_w%02d_r%02d' ${candidate_topology_basename} ${num_rewirings} ${rewired_topology_number}`
      c_t=`printf '%s_w%02d' ${c_t_b} ${num_rewirings}`
      add_command $scriptname "./netoptrew -s ${rndseed} -l -o ${offset} -R ${num_optimisations} -e ${equilibration_timesteps} -n ${topology_name} -c ${candidate_topology} -u ${distance_measurement} -L $logfile -T $transformerfile -g ${gradientfile}"
      rndseed=`expr ${rndseed} + 1`
      rewired_topology_number=`expr ${rewired_topology_number} + 1`
    done
    if [[ $target_parameterisation_number -eq 1 ]]
      then
      do_run qsub ${scriptname}
    fi
  done
}


optimise ()
{
  for gentype in ${gentype_list} ; do
    target_topology_number=1
    echo $target_topology_number
    echo $num_target_topologies
    while test ${target_topology_number} -le ${num_target_topologies} ; do
      target_parameterisation_number=1
      while test ${target_parameterisation_number} -le ${num_target_parameterisations} ; do
        topology_name=`printf 'target_%s%02d_p%02d' ${gentype} ${target_topology_number} ${target_parameterisation_number} `
        candidate_topology_basename=`printf 'candidate_%s%02d_p%02d' ${gentype} ${target_topology_number} ${target_parameterisation_number}`
        t=`expr $target_parameterisation_number + 1`
        c_t_b=`printf 'candidate_%s%02d_p%02d' ${gentype} ${target_topology_number} ${t}`
	echo $c_t_b
        #optimise_numrewired_cluster
        target_parameterisation_number=`expr ${target_parameterisation_number} + 1`
      done
      target_topology_number=`expr ${target_topology_number} + 1`
    done
  done
}


generate_candidate_programs ()
{
  for gentype in ${gentype_list} ; do
    target_topology_number=1
    while test ${target_topology_number} -le ${num_target_topologies} ; do
      target_topology_name=`printf '%s_%02d' ${gentype} ${target_topology_number}`
      target_topology_file=${target_topology_name}.tra
      echo $target_topology_file
      candidate_topology_basename=`printf 'candidate_%s%02d' ${gentype} ${target_topology_number}`
      target_parameterisation_number=1
      while test ${target_parameterisation_number} -le ${num_target_parameterisations} ; do
        tp_name=`printf '%s_p%02d' ${candidate_topology_basename} ${target_parameterisation_number}`
        for num_rewirings in ${num_rewirings_list} ; do
            #echo ${tp_name}
            #echo $num_rewirings #w
            #echo $num_rewired_topologies #r
            ../transsyswork/modeldiscrimination/trunk/transsysrewire -w ${num_rewirings} -n ${tp_name} -r ${num_rewired_topologies} -s ${rndseed} ${target_topology_file}
            rndseed=`expr ${rndseed} + 1`
        done
        target_parameterisation_number=`expr ${target_parameterisation_number} + 1`
      done
      target_topology_number=`expr ${target_topology_number} + 1`
    done
  done
}


optimise_transsys_programs ()
{
  for gentype in ${gentype_list} ; do
    target_topology_number=1
    while test ${target_topology_number} -le ${num_target_topologies} ; do
      target_topology_name=`printf 'target_%s%02d' ${gentype} ${target_topology_number}`
      target_topology_file=${target_topology_name}.tra
      candidate_topology_basename=`printf 'candidate_%s%02d' ${gentype} ${target_topology_number}`
      target_parameterisation_number=1
      while test ${target_parameterisation_number} -le ${num_target_parameterisations} ; do
        tp_name=`printf '%s_p%02d' ${candidate_topology_basename} ${target_parameterisation_number}`
        for num_rewirings in ${num_rewirings_list} ; do
          rewired_topology=1
          while test ${rewired_topology} -le ${num_rewired_topologies} ; do
            model=`printf '%s_p%02d_w%02d_r%02d' ${candidate_topology_basename} ${target_parameterisation_number} $num_rewirings $rewired_topology`
            #echo ${tp_name}
            #echo $num_rewirings #w
            #echo $num_rewired_topologies #r
            echo $model
            ../transsyswork/modeldiscrimination/trunk/netopt -x  ${empirical_data} -o ${simgenex_model} -R ${num_optimisations} -g ${gradientfile} -T ${transformerfile} -s ${rndseed} -c ${model} 'opt_'${model}'.txt' 'tp_'${model}'.txt' 'log.txt'
            
	    #../transsyswork/modeldiscrimination/trunk/transsysrewire -w ${num_rewirings} -n ${tp_name} -r ${num_rewired_topologies} -s ${rndseed} ${target_topology_file}
            rewired_topology=`expr ${rewired_topology} + 1`
            rndseed=`expr ${rndseed} + 1`
            done
        done
        target_parameterisation_number=`expr ${target_parameterisation_number} + 1`
      done
      target_topology_number=`expr ${target_topology_number} + 1`
    done
  done
}

# This function optimise transsys programs created at random from a list of genes and factors
optimise_transsys_candidate_programs ()
{
  for gentype in ${gentype_list} ; do
    echo $gentype
    target_topology_number=1
    while test ${target_topology_number} -le ${num_target_topologies} ; do
      target_topology_name=`printf 'target_%s%02d' ${gentype} ${target_topology_number}`
      target_topology_file=${target_topology_name}.tra
      candidate_topology_basename=`printf 'target_%s%02d' ${gentype} ${target_topology_number}`
      target_parameterisation_number=0
      #echo $target_topology_number
      while test ${target_parameterisation_number} -le ${num_target_parameterisations} ; do
        tp_name=`printf '%s_p%02d' ${candidate_topology_basename} ${target_parameterisation_number}`
        for num_rewirings in ${num_rewirings_list} ; do
          rewired_topology=0
          while test ${rewired_topology} -le ${num_rewired_topologies} ; do
            model=`printf '%s_p%02d_w%02d_r%02d' ${candidate_topology_basename} ${target_parameterisation_number} $num_rewirings $rewired_topology`
            #echo ${tp_name}
            #echo $num_rewirings #w
            #echo $num_rewired_topologies #r
            echo $model
            ../transsyswork/modeldiscrimination/trunk/netopt -x  ${empirical_data} -o ${simgenex_model} -R ${num_optimisations} -g ${gradientfile} -T ${transformerfile} -s ${rndseed} -c ${model} 'opt_'${model}'.txt' 'tp_'${model}'.txt' 'log.txt'
            
	    #../transsyswork/modeldiscrimination/trunk/transsysrewire -w ${num_rewirings} -n ${tp_name} -r ${num_rewired_topologies} -s ${rndseed} ${target_topology_file}
            rewired_topology=`expr ${rewired_topology} + 1`
            rndseed=`expr ${rndseed} + 1`
            done
        done
        target_parameterisation_number=`expr ${target_parameterisation_number} + 1`
      done
      target_topology_number=`expr ${target_topology_number} + 1`
    done
  done
}




maketable () # compile fitness results
{
  rm -fr fitn*
  name=""
  for gentype in ${gentype_list} ; do
    target_topology_number=1
    while test ${target_topology_number} -le ${num_target_topologies} ; do
      target_parameterisation_number=1
      while test ${target_parameterisation_number} -le ${num_target_parameterisations} ; do
        candidate_topology_basename=`printf '%s_%s%02d_p%02d' $tp_type ${gentype} ${target_topology_number} ${target_parameterisation_number}`
        for num_rewirings in ${num_rewirings_list} ; do
          rewired_topology_number=1
            while test ${rewired_topology_number} -le ${num_rewired_topologies} ; do
              candidate_topology=`printf '%s_w%02d_r%02d' ${candidate_topology_basename} ${num_rewirings} ${rewired_topology_number}`
              candidate_topology_logo=`printf 'log.txt_%s.txt' ${candidate_topology}`
              cp $candidate_topology_logo $candidate_topology_logo'.bk'
	      echo $candidate_topology_logo 
              sed 's/rst/'$target_topology_number'\t'$target_parameterisation_number'\t'$num_rewirings'\t'$rewired_topology_number'\t/g' $candidate_topology_logo'.bk' > clean.txt
              mv clean.txt $candidate_topology_logo
              rm -f $candidate_topology_logo'.bk'
              name=`printf '%s %s ' $name $candidate_topology_logo `
              rewired_topology_number=`expr ${rewired_topology_number} + 1`
            done
        done
        target_parameterisation_number=`expr ${target_parameterisation_number} + 1`
      done
    target_topology_number=`expr ${target_topology_number} + 1`
    done
    cat $name > 'tt.txt'
    sed '/restart/d' 'tt.txt' > 'fitnesstable.txt'
    rm -f 'tt.txt'
  done
}

maketable_target_null () # create transsys program
{
  name=""
  for gentype in ${gentype_target_list} ; do
    echo $gentype
    target_topology_number=1
    target_parameterisation_number=1
    rewired_topology_number=1
    num_rewirings=$gentype
    candidate_topology_basename=`printf 'candidate_%s%02d_p%02d' ${gentype} ${target_topology_number} ${target_parameterisation_number}`
    #candidate_topology=`printf '%s_w%02d_r%02d' ${candidate_topology_basename} ${num_rewirings} ${rewired_topology_number}`
    candidate_topology_logo=`printf 'log.txt_%s.txt' ${gentype}`
    echo $candidate_topology_logo
    cp $candidate_topology_logo $candidate_topology_logo'.bk'
    sed 's/rst/'$gentype'\t'$target_parameterisation_number'\t'$num_rewirings'\t'$rewired_topology_number'\t/g' $candidate_topology_logo'.bk' > clean.txt
    mv clean.txt $candidate_topology_logo
    rm -f $candidate_topology_logo'.bk'
    name=`printf '%s %s ' $name $candidate_topology_logo `
    rewired_topology_number=`expr ${rewired_topology_number} + 1`
    cat $name > 'tt.txt'
    sed '/restart/d' 'tt.txt' > 'fitnesstable_target.txt'
    rm -f 'tt.txt'
  done
  cat 'fitnesstable.txt' 'fitnesstable_target.txt' > 'fitness_all.txt' 
}



simgenex_model=wheat_senescence.sgx
signal_to_noise=0
rndseed=2
true_model=wheat_senescence
num_optimisations=100
transformerfile=transformerfile.dat
logfile=logo
gradientfile=optspec.dat
empirical_data=wheat_senescence.txt
#tp_candidate=candidate_er01_p01_w00_r01
gentype_list='wheat_senescence33'
#wheat_senescence'
gentype_target_list='wheat_senescence33_01 wheat_senescence_m1 wheat_senescence_m2 wheat_senescence_m3 wheat_senescence_m4 wheat_senescence_m5 wheat_senescence_null'
num_target_topologies=1
num_rewirings_list='0 1 2 3 4 5 6 7 9 11'
#13 15 18 22 27 32 38 46 55 66'
num_target_parameterisations=1
num_rewired_topologies=1
tp_type='candidate'



while getopts m:e:s:o:d opt
do
  case "$opt" in
    m) tp_candidate="$OPTARG";;
    e) empirical_data="$OPTARG";;
    s) simgenex_model="$OPTARG";;
    o) num_optimisations="$OPTARG";;
    d) isdef=1;;
    \?) help_ani;;
  esac
done


checkpython
#generate_target_programs
#generate_candidate_programs
#optimise_transsys_programs
#optimise_transsys_candidate_programs # from random transsys program generator
optimiseModelEmpiric
#maketable
maketable_target_null
