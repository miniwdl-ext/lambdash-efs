//
// lambdash - AWS Lambda function to run shell commands
//
// See also: https://alestic.com/2014/11/aws-lambda-shell/
//
// process.env['PATH'] = process.env['PATH'] + ':' + process.cwd()
// var AWS = require('aws-sdk');
var exec = require('child_process').exec;
var MAX_OUTPUT = 64 * 1024 * 1024; // 64 MiB

function ship(outp) {
    if (outp === null) {
        return null;
    }
    return Buffer.from(outp, 'binary').toString('base64');
}

exports.handler = function(event, context) {
    var execOptions = {
        encoding: 'binary',
        maxBuffer: MAX_OUTPUT,
        shell: '/bin/bash'
    };
    exec(event.command, execOptions,
        function (error, stdout, stderr) {
            var result = {
                "stdout": ship(stdout),
                "stderr": ship(stderr),
                "error": error
            };
            context.succeed(result);
        }
    );
}
