PR_URLS=(
    "https://github.com/RedHatInsights/dvo-extractor/pull/50"
    "https://github.com/RedHatInsights/insights-results-aggregator/pull/1993"
    "https://github.com/RedHatInsights/insights-behavioral-spec/pull/592"
    "https://github.com/RedHatInsights/insights-results-aggregator-utils/pull/382"
    "https://github.com/RedHatInsights/insights-results-aggregator-mock/pull/494"
    "https://github.com/RedHatInsights/insights-content-template-renderer/pull/74"
    "https://github.com/RedHatInsights/insights-operator-gathering-conditions-service/pull/215"
    "https://github.com/RedHatInsights/insights-results-aggregator-exporter/pull/266"
    "https://github.com/RedHatInsights/ccx-notification-writer/pull/441"
    "https://github.com/RedHatInsights/ccx-notification-service/pull/721"
    "https://github.com/RedHatInsights/insights-results-aggregator-cleaner/pull/303"
    "https://github.com/RedHatInsights/insights-results-smart-proxy/pull/1253"
    "https://github.com/RedHatInsights/insights-content-service/pull/578"
)

echo "PR url,checks status"
for pr_url in "${PR_URLS[@]}"
do
    GH_PAGER=cat gh pr checks $pr_url 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        echo "$pr_url,PASS"
    else
        echo "$pr_url,FAIL"
    fi
done