const process = require('process')

if (process.argv.length < 3) {
    console.error('Invalid format. Expected HH:MM')
    process.exit(69)
}

const startTimeString = process.argv[2]
const [startHours, startMinutes] = startTimeString.split(':').map(Number)

if (
    isNaN(startHours) || isNaN(startMinutes) ||
    startHours > 23 || startMinutes > 59
) {
    console.error('Invalid time format. Expected HH:MM format WITH VALID TIME')
    process.exit(69)
}

const startTime = new Date()
startTime.setHours(startHours, startMinutes, 0, 0)

const targetTime = new Date(startTime.getTime() + 5 * 60 * 60 * 1000) // 5 hours after startTime
targetTime.setSeconds(0) // fixes the precise time, we don't want them
targetTime.setMilliseconds(0)

const currentTime = new Date()
currentTime.setSeconds(0)
currentTime.setMilliseconds(0)

if (currentTime.getTime() === targetTime.getTime()) {
    console.log('[checkTime] time matches, now exiting with status 0 to make another runtime')
    process.exit(0)
} else {
    process.exit(1)
}
