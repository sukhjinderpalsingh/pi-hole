#!/usr/bin/env bats
# Tests for utils.sh

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-file/load'

setup() {
    TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
    temp_del "${TEST_TEMP_DIR}"
}

# In case of test failure post the whole output of the run command
bats::on_failure() {
    printf "\n"
    printf "═══════════════════════════════════════════════════════════════════════════════\n"
    printf "                              BATS TEST FAILURE DEBUG                         \n"
    printf "═══════════════════════════════════════════════════════════════════════════════\n"
    printf "\n"
    printf "   TEST DESCRIPTION:\n"
    printf "   %s\n" "${BATS_TEST_DESCRIPTION}"
    printf "\n"
    printf "   COMMAND EXECUTED:\n"
    printf "   %s\n" "${BATS_RUN_COMMAND}"
    printf "\n"
    printf "   OUTPUT CAPTURED:\n"
    printf "   %s\n" "${output}"
    printf "\n"
    printf "═══════════════════════════════════════════════════════════════════════════════\n"
    printf "\n"
}

# ---------------------------------------------------------------------------

@test "addOrEditKeyValPair adds and replaces key-value pairs correctly" {
    local outfile="${TEST_TEMP_DIR}/testoutput"
    bash -c "
        source /opt/pihole/utils.sh
        addOrEditKeyValPair '${outfile}' 'KEY_ONE' 'value1'
        addOrEditKeyValPair '${outfile}' 'KEY_TWO' 'value2'
        addOrEditKeyValPair '${outfile}' 'KEY_ONE' 'value3'
        addOrEditKeyValPair '${outfile}' 'KEY_FOUR' 'value4'
    "
    assert_file_exists "${outfile}"
    assert_file_contains "${outfile}" "KEY_ONE=value3"
    assert_file_contains "${outfile}" "KEY_TWO=value2"
    assert_file_contains "${outfile}" "KEY_FOUR=value4"
    assert_file_not_contains "${outfile}" "KEY_ONE=value1"
}

@test "getFTLPID returns -1 when FTL is not running" {
    run bash -c "
        source /opt/pihole/utils.sh
        getFTLPID
    "
    assert_output "-1"
}

@test "setFTLConfigValue and getFTLConfigValue round-trip" {
    # FTL must be installed for this test
    bash -c "
        source /opt/pihole/basic-install.sh
        create_pihole_user
        funcOutput=\$(get_binary_name)
        echo 'development' > /etc/pihole/ftlbranch
        binary=\"pihole-FTL\${funcOutput##*pihole-FTL}\"
        theRest=\"\${funcOutput%pihole-FTL*}\"
        FTLdetect \"\${binary}\" \"\${theRest}\"
    "
    run bash -c "
        source /opt/pihole/utils.sh
        setFTLConfigValue 'dns.upstreams' '[\"9.9.9.9\"]' > /dev/null
        getFTLConfigValue 'dns.upstreams'
    "
    assert_output --partial "[ 9.9.9.9 ]"
}
