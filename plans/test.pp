plan kvm_automation_tooling::test() {
  $result = run_command('test -f ./foobar', 'localhost', 'catch_errors' => true)
  out::message("Result: ${result.ok}")
}
