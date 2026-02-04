#!/bin/bash
#
# Quick helper to check media scan progress
#

sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no youruser@192.168.1.11 'bash' << 'EOFCHECK'
#!/bin/bash
clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      📊 HIGH-PRIORITY MEDIA SCAN STATUS                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Check screen session
if screen -list | grep -q media_scan; then
    echo "✅ Scan Status: RUNNING"
    echo ""

    # Get progress
    tmpdir=$(ls -d /tmp/media_scan_* 2>/dev/null | head -1)
    if [ -d "$tmpdir" ]; then
        total_progress=0
        for i in $(seq 1 8); do
            if [ -f "$tmpdir/progress_$i.txt" ]; then
                p=$(wc -l < "$tmpdir/progress_$i.txt" 2>/dev/null | tr -d ' ')
                total_progress=$((total_progress + p))
            fi
        done

        # Get file list to count total
        if [ -f "$tmpdir/sorted_files.txt" ]; then
            total_files=$(wc -l < "$tmpdir/sorted_files.txt" 2>/dev/null | tr -d ' ')
        else
            total_files=392
        fi

        pct=$((total_progress * 100 / total_files))

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Progress:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Progress bar
        filled=$((pct / 2))
        empty=$((50 - filled))
        printf "  ["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "] %3d%%\n" $pct
        echo ""
        printf "  Files Scanned: %d / %d\n" $total_progress $total_files
        echo ""

        # Results
        if [ -f "$tmpdir/batch_1.txt" ]; then
            clean=$(cat "$tmpdir"/batch_*.txt 2>/dev/null | grep -c "^OK" || echo "0")
            suspicious=$(cat "$tmpdir"/batch_*.txt 2>/dev/null | grep -c "^SUSPICIOUS" || echo "0")
            corrupt=$(cat "$tmpdir"/batch_*.txt 2>/dev/null | grep -c "^CORRUPT" || echo "0")

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Results So Far:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            printf "  ✅ Clean:      %-5d (%.1f%%)\n" $clean $(echo "scale=1; $clean * 100 / $total_progress" | bc 2>/dev/null || echo "0")
            printf "  ⚠️  Suspicious: %-5d (%.1f%%)\n" $suspicious $(echo "scale=1; $suspicious * 100 / $total_progress" | bc 2>/dev/null || echo "0")
            printf "  ❌ Corrupt:    %-5d (%.1f%%)\n" $corrupt $(echo "scale=1; $corrupt * 100 / $total_progress" | bc 2>/dev/null || echo "0")
            echo ""

            if [ $corrupt -gt 0 ]; then
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "⚠️  Corrupted Files Found:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                cat "$tmpdir"/batch_*.txt 2>/dev/null | grep "^CORRUPT" | cut -d'|' -f3 | while read fname; do
                    echo "  ❌ $fname"
                done
                echo ""
            fi
        fi

        # Worker status
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Active Workers:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        for i in $(seq 1 8); do
            if [ -f "$tmpdir/current_$i.txt" ]; then
                p=$(wc -l < "$tmpdir/progress_$i.txt" 2>/dev/null | tr -d ' ')
                c=$(cat "$tmpdir/current_$i.txt" 2>/dev/null | tr -d '\n')
                if [ -z "$c" ]; then
                    printf "  W%d [%3d]: Idle\n" $i $p
                else
                    printf "  W%d [%3d]: %s\n" $i $p "${c:0:45}"
                fi
            fi
        done
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 To view live updating progress:"
    echo "   ssh youruser@192.168.1.11"
    echo "   screen -r media_scan"
    echo "   (Press Ctrl+A then D to detach)"

else
    echo "⚠️  Scan Status: NOT RUNNING"
    echo ""

    # Check if report exists
    if ls /tmp/high_priority_scan_report_*.txt 1> /dev/null 2>&1; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ SCAN COMPLETE!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        latest_report=$(ls -t /tmp/high_priority_scan_report_*.txt 2>/dev/null | head -1)

        if [ -f "$latest_report" ]; then
            clean=$(grep -c "^OK" "$latest_report" 2>/dev/null || echo "0")
            suspicious=$(grep -c "^SUSPICIOUS" "$latest_report" 2>/dev/null || echo "0")
            corrupt=$(grep -c "^CORRUPT" "$latest_report" 2>/dev/null || echo "0")
            total=$((clean + suspicious + corrupt))

            echo "  Report: $latest_report"
            echo ""
            echo "  Final Results:"
            printf "    ✅ Clean:      %-5d (%.1f%%)\n" $clean $(echo "scale=1; $clean * 100 / $total" | bc 2>/dev/null || echo "0")
            printf "    ⚠️  Suspicious: %-5d (%.1f%%)\n" $suspicious $(echo "scale=1; $suspicious * 100 / $total" | bc 2>/dev/null || echo "0")
            printf "    ❌ Corrupt:    %-5d (%.1f%%)\n" $corrupt $(echo "scale=1; $corrupt * 100 / $total" | bc 2>/dev/null || echo "0")
            echo ""

            if [ $corrupt -gt 0 ]; then
                echo "  ❌ Corrupted Files:"
                grep "^CORRUPT" "$latest_report" | cut -d'|' -f3 | while read fname; do
                    echo "    • $fname"
                done
                echo ""
                echo "  Full paths available in report file"
            fi
        fi
    else
        echo "No scan report found. The scan may have been interrupted."
    fi
fi

echo ""

EOFCHECK

