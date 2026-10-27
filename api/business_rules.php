<?php
declare(strict_types=1);

function borrowing_window_open(?DateTimeImmutable $now = null): bool
{
    $manila = new DateTimeZone('Asia/Manila');
    $localTime = ($now ?? new DateTimeImmutable('now', $manila))->setTimezone($manila);
    $minutesAfterMidnight = ((int)$localTime->format('G') * 60) + (int)$localTime->format('i');

    return $minutesAfterMidnight >= 8 * 60 && $minutesAfterMidnight < 19 * 60;
}
