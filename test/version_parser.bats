#!/usr/bin/env bats

export BATS_JOURNAL="$BATS_TMPDIR/$BATS_TEST_NAME.journal"
export BATS_FIXTURE="$BATS_TMPDIR/$BATS_TEST_NAME.fixture"

@test "General minor versions get adapted to specific matchers" {
	matcher=$(./bin/version_parser.sh 9.4)
	[[ "9.370" =~ $matcher ]]
	[[ "9.400" =~ $matcher ]]
	[[ "9.413" =~ $matcher ]]
	[[ ! "9.501" =~ $matcher ]]
	[[ ! "9.354" =~ $matcher ]]
}

@test "Specific minor versions are not modified" {
	result=$(./bin/version_parser.sh 9.412)
	[[ $result == "9.412" ]]
}
