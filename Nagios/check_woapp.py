#!/usr/bin/python

import sys, argparse, logging, json, httplib2
from restclient import GET, POST, PUT, DELETE

class WOApp():
    def __init__(self, type='app', url='http://localhost:56789/cgi-bin/WebObjects/JavaMonitor.woa/', password=None, name='JavaMonitor'):
        self.type = type
        self.url = url + "/admin/info"
        self.password = password
        self.appname = name
        self.url = self.url + "?type=" + self.type + "&name=" + self.appname
        if self.password != None:
            self.url = self.url + "&pw=" + self.password

    def results(self):
        try:
            response = GET(self.url, accept=['application/json'])
        except httplib2.ServerNotFoundError as e:
            print "WARNING : Couldn't connect to JavaMonitor at " + self.url
            sys.exit(1)
        try:
            details = json.loads(response)[0]
            return details
        except ValueError as e:
            print "Unknown status : Couldn't convert JSON to object"
            sys.exit(3)

def transform_to_bool(bool_as_str):
    if bool_as_str.upper() == 'TRUE':
        return True
    else:
        return False

def main():
    argp = argparse.ArgumentParser(description=__doc__)
    argp.add_argument('-t', '--type', default='app', help='type can be: \"app\" or \"ins"')
    argp.add_argument('-u', '--url', default='http://localhost:56789/cgi-bin/WebObjects/JavaMonitor.woa', help='URL to JavaMonitor. Default value is http://localhost:56789/cgi-bin/WebObjects/JavaMonitor.woa')
    argp.add_argument('-p', '--password', default=None, help='Monitor password.')
    argp.add_argument('-n', '--name', default='JavaMonitor', help='name of the application. if you are checking a specific instance, it have to be Name-InstanceNumber (example: AjaxExample-1)')
    argp.add_argument('-st', '--state', default=None, help='check the state of the app or instance. Pass \"ALIVE\" or \"DEAD\" as the value')
    argp.add_argument('-de', '--deaths', default=None, help='check if the app have any more than X deaths')
    argp.add_argument('-rn', '--refusingNewSessions', default=None, help='check if the app is refusing new sessions, pass False or True as the argument')
    argp.add_argument('-ar', '--autoRecover', default=None, help='check if autoRecover is true or false, pass False or True as the argument')
    argp.add_argument('-as', '--activeSessions', default=None, help='check the count of active sessions')
    args = argp.parse_args()
    
    check_state = 0
    check_msg = ''
    
    details = WOApp(args.type,args.url,args.password,args.name)
    results = details.results()
    
    if (args.state is not None):
        status = results.get('state')
        print args.name + " is " + status
        if args.state != status:
            sys.exit(2)
            
    if (args.deaths is not None):
        deaths = results.get('deaths')
        print args.name + " have " + deaths + " deaths"
        if deaths > args.deaths:
            sys.exit(2)

    if (args.activeSessions is not None):
        activeSessions = results.get('activeSessions')
        print args.name + " have " + activeSessions + " active sessions"
        if activeSessions > args.activeSessions:
            sys.exit(2)
    
    if (args.refusingNewSessions is not None):
        refusingNewSessions = results.get('refusingNewSessions')
        arg_bool = transform_to_bool(args.refusingNewSesions)
        if refusingNewSessions:
            print args.name + "is refusing new sessions"
        else:
            print args.name + "is not refusing new sessions"
        if refusingNewSessions == arg_bool:
            sys.exit(2)
            
    if (args.autoRecover is not None):
        autoRecover = results.get('autoRecover')
        arg_bool = transform_to_bool(args.autoRecover)
        if autoRecover:
            print "Autorecover for " + args.name + " is enabled"
        else:
            print "Autorecover for " + args.name + " is disabled"
        if autoRecover == arg_bool:
            sys.exit(2)
            
    sys.exit(0)

if __name__ == '__main__':
    main()