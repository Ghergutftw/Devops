1. buildDiscarder(logRotator(numToKeepStr: '10'))
Purpose: Manages build history and storage

What it does: Automatically deletes old builds to save disk space
numToKeepStr: '10': Keeps only the last 10 builds
Why use it: Prevents Jenkins from running out of disk space over time
Alternative options:
groovybuildDiscarder(logRotator(
    numToKeepStr: '10',        // Keep 10 builds
    daysToKeepStr: '30',       // Keep builds for 30 days
    artifactNumToKeepStr: '5', // Keep artifacts for 5 builds
    artifactDaysToKeepStr: '14' // Keep artifacts for 14 days
))


2. timeout(time: 30, unit: 'MINUTES')
Purpose: Sets a maximum execution time for the entire pipeline

What it does: Automatically kills the pipeline if it runs longer than 30 minutes
Why use it: Prevents hanging builds that consume resources indefinitely
Common scenarios: Network issues, infinite loops, stuck processes
Alternative units: 'SECONDS', 'MINUTES', 'HOURS', 'DAYS'

3. timestamps()
Purpose: Adds timestamps to console output

What it does: Shows when each step/command was executed
Example output:
12:34:56  Building project with Maven...
12:35:12  [INFO] BUILD SUCCESS
12:35:13  Finished: SUCCESS

Why use it: Essential for debugging performance issues and tracking execution time

4. ansiColor('xterm')
Purpose: Enables colored console output

What it does: Shows colored text in Jenkins console (green for success, red for errors, etc.)
'xterm': Terminal type for color support
Why use it: Makes console output much more readable
Requires: AnsiColor plugin (that's why you got the error)

5. skipDefaultCheckout()
Purpose: Prevents automatic source code checkout

What it does: Skips the default Git checkout that normally happens automatically
Why use it: Gives you control over when and how to checkout code
Benefits:

Custom checkout options (shallow clone, specific branches)
Better error handling
Conditional checkouts

Best Practices

Always use timeout() - Prevents runaway builds
Use buildDiscarder() - Essential for disk space management
Enable timestamps() - Critical for debugging
Use skipDefaultCheckout() - Gives better control over source code
Add disableConcurrentBuilds() - Prevents resource conflicts

These options make your pipeline more robust, maintainable, and easier to debug.