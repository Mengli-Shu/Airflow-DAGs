
while echo "Running Airflow Scheduler..."; do
  # Failure: Logging date txt file
  date >> "$(pwd)"/logs/run_airflow/log_forever_script.txt
  airflow scheduler
  sleep 1
  echo "sleep for 1 second...."
  sleep 1
done
