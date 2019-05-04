### Define here local variables #####
#####################################
# chmod +x runBadger.sh
# ./runBadger.sh
#

trap "exit" INT

# time bound for each run (in seconds):
time_bound=180 # 18000 = 5 hours (currently 3 min)

# number of experiments
number_of_runs=1 #5

# subject
subject=01-rsa
# subject=07-smart_contract

# folder with binaries
bin=. #./example
# bin=../evaluation/07_smart_contract

# badger=1, kelinciwca=2, symexe=3
execution_mode=1

# server parameter
# server_param="InsertionSortFuzz @@"
server_param="Sample @@"

# CostMetric, use "jumps" or "userdefined"
costMetric="userdefined"

# Path to afl-fuzz
pathToAFL=/home/heman/Documents/undergrad/security/final-proj/afl-2.52b/afl-fuzz

# Path to KelinciWCA interface
pathToKelinciWCAInterface=/home/heman/Documents/undergrad/security/final-proj/kelinci/fuzzerside/interface

# Path to jpf-core
pathToJPF=/home/heman/Documents/undergrad/security/final-proj/jpf-core

# Path to jpf-symbc
pathToSPF=/home/heman/Documents/undergrad/security/final-proj/jpf-symbc

# Path to Badger
pathToBadger=/home/heman/Documents/undergrad/security/final-proj/badger/badger

# Path to Z3
pathToZ3=$pathToSPF/lib

#####################################
#####################################

if [ $execution_mode -eq 1 ]
then
  target=./experiment-results/$subject-badger
elif [ $execution_mode -eq 2 ]
then
  target=./experiment-results/$subject-kelinciwca
elif [ $execution_mode -eq 3 ]
then
  target=./experiment-results/$subject-symexe
fi

echo ""
echo "Running experiments for:"
echo "subject=$subject"
echo "execution_mode=$execution_mode"
echo "time_bound=$time_bound"
echo "number_of_runs=$number_of_runs"
echo "bin=$bin"
echo "target=$target"
echo "server_param=$server_param"
echo ""

mkdir -p ./experiment-results

for i in `seq 1 $number_of_runs`
do

  current_target="$target-$i"
  echo "Initializing experiment environment for run=$i"

  mkdir "$current_target"
  cp -r "$bin/kelinciwca_analysis" "$current_target/"

  # Copy Symexe only for Badger or Symexe
  if [ $execution_mode -eq 1 ]
  then
    cp -r "$bin/symexe_analysis" "$current_target/"
    cp "$bin/config" "$current_target"
  elif [ $execution_mode -eq 3 ]
  then
    cp -r "$bin/symexe_analysis" "$current_target/"
    cp "$bin/config" "$current_target"
  fi

  cd "$current_target"

  # Start server and AFL only for Badger, KelinciWCA.
  if [ $execution_mode -lt 3 ]
  then
    cd "./kelinciwca_analysis"
    echo "Starting server.."
    nohup java -cp ./bin-instr/ edu.cmu.sv.kelinci.Kelinci $server_param > ./server-log.txt &
    server_pid=$!

    echo "Starting AFL-WCA.."
    # AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 nohup $pathToAFL -i ./in_dir -o ./fuzzer-out -c $costMetric -S afl -t 999999999 $pathToKelinciWCAInterface @@ > ./afl-log.txt &
    AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 nohup $pathToAFL -i ./in_dir -o ./fuzzer-out -S afl -t 999999999 $pathToKelinciWCAInterface @@ > ./afl-log.txt &
    afl_pid=$!
    cd ..
  fi

  if [ $execution_mode -eq 1 ]
  then
    echo "Starting SymExe.."
    DYLD_LIBRARY_PATH=$pathToZ3 nohup java -Xmx10240m -cp "$pathToBadger/build/*:$pathToBadger/lib/*:$pathToJPF/build/*:$pathToSPF/build/*:$pathToSPF/lib/*" edu.cmu.sv.badger.app.BadgerRunner config > ./spf-log.txt &
    spf_pid=$!
  fi
  if [ $execution_mode -eq 3 ]
  then
    echo "Starting SymExe.."
    DYLD_LIBRARY_PATH=$pathToZ3 nohup java -Xmx10240m -cp "$pathToBadger/build/*:$pathToBadger/lib/*:$pathToJPF/build/*:$pathToSPF/build/*:$pathToSPF/lib/*" edu.cmu.sv.badger.app.BadgerRunner config > ./spf-log.txt &
    spf_pid=$!
  fi

  echo "Waiting for $time_bound seconds.."
  sleep $time_bound

  if [ $execution_mode -eq 1 ]
  then
    echo "Stopping SPF.."
    kill $spf_pid
  fi
  if [ $execution_mode -eq 4 ]
  then
    echo "Stopping SPF.."
    kill $spf_pid
  fi

  if [ $execution_mode -lt 4 ]
  then
    echo "Stopping AFL.."
    kill $afl_pid

    echo "Stopping server.."
    kill $server_pid
  fi

  echo "Finished run=$i"
  echo ""

done

echo "Done."
