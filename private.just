# Private commands, do not share with anyone

# Show today's agenda from work google calendar
agenda:
    gcalcli agenda --calendar="tkral@redhat.com" --details=end --details=url --nodeclined --tsv  "`date +"%Y-%m-%d"` 00:00" "`date +"%Y-%m-%d"` 23:59" | awk -F $'\t' '{print "- " $2 " - " $4 " [" $7 "](" $5 ")"}'