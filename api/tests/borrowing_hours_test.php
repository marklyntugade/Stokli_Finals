<?php
declare(strict_types=1);

require_once __DIR__ . '/../business_rules.php';

$cases = [
    '07:59 is closed' => ['2026-10-18 07:59:00', false],
    '08:00 is open' => ['2026-10-18 08:00:00', true],
    '18:59 is open' => ['2026-10-18 18:59:59', true],
    '19:00 is closed' => ['2026-10-18 19:00:00', false],
    'midnight is closed' => ['2026-10-18 00:00:00', false],
];

foreach ($cases as $label => [$time, $expected]) {
    $actual = borrowing_window_open(
        new DateTimeImmutable($time, new DateTimeZone('Asia/Manila'))
    );
    if ($actual !== $expected) {
        fwrite(STDERR, "FAIL: {$label}\n");
        exit(1);
    }
}

fwrite(STDOUT, 'All borrowing-hours tests passed.' . PHP_EOL);
