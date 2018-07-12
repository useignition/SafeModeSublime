//
//  ViewController.m
//  SafeMode
//
//  Created by Ignition on 10/7/18.
//  Copyright © 2018 @useignition. All rights reserved.
//

#import "ViewController.h"
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>
#include <dlfcn.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#import "FCAlertView.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

int springboard_restart() {
    NSLog(@"Forking child process to restart springboard");
    pid_t child = fork();
    if(child == 0){
        NSLog(@"Child Process - Restarting springboard");
        // Now we're in child process
        execlp("/bin/launchctl","launchctl","stop","com.apple.SpringBoard",NULL);
        sleep(1);
        exit(1);
    }
    NSLog(@"Child process %d forked, suiciding...",child);
    //exit(1);
    return 0;
}

NSString* osVersionString(){
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

static int _osVersionValue = -1;
int osVersion(){
    if(_osVersionValue < 0){
        // We assume the strings is as:
        // Version 1.x.x (Build XXXX)
        NSString* s = osVersionString();
        if([s hasPrefix:@"Version "]){
            if([s length] >= 13 ){
                char buf[] = {0x0,0x0};
                buf[0] = [s characterAtIndex:8];
                int i1 = atoi(buf);
                buf[0] = [s characterAtIndex:10];
                int i2 = atoi(buf);
                buf[0] = [s characterAtIndex:12];
                int i3 = atoi(buf);
                _osVersionValue = i1 * 100 + i2 * 10 + i3;
                NSLog(@"OS Version is %d",_osVersionValue);
                return _osVersionValue;
            }
        }
        _osVersionValue = 0;
    }
    return _osVersionValue;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openScheme:(NSString *)scheme {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:scheme];
    
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:URL options:@{}
           completionHandler:^(BOOL success) {
               NSLog(@"Open %@: %d",scheme,success);
           }];
    } else {
        BOOL success = [application openURL:URL];
        NSLog(@"Open %@: %d",scheme,success);
    }
}

- (IBAction)respring:(id)sender {
    FCAlertView *alert = [[FCAlertView alloc] init];
    
    alert.blurBackground = YES;
    alert.detachButtons = YES;
    alert.bounceAnimations = YES;
    
    [alert makeAlertTypeWarning];
    
    [alert addButton:@"Open Cydia" withActionBlock:^{
        [self openScheme:@"cydia://"];
    }];
    
    [alert doneActionBlock:^{
        pid_t pid;
        int status;
        const char* args[] = {"killall", "-9", "SpringBoard", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
        waitpid(pid, &status, WEXITED);//wait untill the process completes (only if you need to do that)
        springboard_restart();
    }];
    
    
    [alert showAlertInView:self
                 withTitle:@"Respring"
              withSubtitle:@"Are you sure you want to respring? It's recomended that you remove the tweak(s) that caused this."
           withCustomImage:nil
       withDoneButtonTitle:@"Respring"
                andButtons:nil];
}

@end
