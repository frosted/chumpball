from __future__ import print_function # Python 2/3 compatibility
import requests
from bs4 import BeautifulSoup


class Player(object):
    '''
    argument(s): 1 dictionary defining the stat values for a player
    '''
    def __init__(self,stats):
        self.name = str(stats['Player'])
        self.team = str(stats['Team'])
        self.gp = stats['GP']
        self.min = stats['MIN']
        self.fgm = stats['FGM']
        self.fga = stats['FGA']
        self.fgp = stats['FGP']
        self.p3m = stats['3PM']
        self.p3a = stats['3PA']
        self.p3p = stats['3PP']
        self.ftm = stats['FTM']
        self.fta = stats['FTA']
        self.ftp = stats['FTP']
        self.tov = int(stats['TOV'])
        self.pv = stats['PF']
        self.orb = stats['ORB']
        self.drb = stats['DRB']
        self.reb = int(stats['REB'])
        self.ast = int(stats['AST'])
        self.stl = stats['STL']
        self.blk = stats['BLK']
        self.pts = int(stats['PTS'])

    def get_value(self):
        self.value = self.pts + self.ast + self.reb - (self.tov * 2)
        return self.value

class Owner(object):

    def __init__(self, name, centers = [], forwards = [], guards = []):
        self.name = name
        self.centers = centers
        self.forwards = forwards
        self.guards = guards

    def add_center(self, player):
        self.centers.append(player)

    def add_forward(self, player):
        self.forwards.append(player)

    def add_guard(self, player):
        self.guards.append(player)

    def list_centers(self):
        for player in self.centers:
            print(player.name)

    def list_forwards(self):
        for player in self.forwards:
            print(player.name)

    def list_guards(self):
        for player in self.guards:
            print(player.name)

def find_player(player_name, all_players):
    # list for all players found matching player_name
    result = []

    # full text search
    for player in all_players:
        # we're looking any occurance of the substring
        if player.name.lower().find(player_name.lower()) != -1:
            # add to list
            result.append(player)

    # if nothing returned, try a fuzzy string compare
    if len(result) == 0:
        # last name search
        for player in all_players:
            # we're looking any occurance of the substring
            if player.name.lower().find(player_name.split(' ')[-1].strip().lower()) != -1:
                # add to list
                result.append(player)

    # if we return more/less than 1 result, throw exception
    if len(result) == 1:
        print('found {}'.format(player_name))
        return result[-1]
    elif len(result) == 0:
        print('{} results, could not find {}'.format(len(result), player_name))
        #raise ValueError('not found','total players returned should be 1, your query returned none.')
    else:
        print('what? {}'.format(result))
        #raise ValueError('too many results','total players returned should be 1')

def scrape_stats(url, section, pages=100):
    header_list = ['omit','omit','Player','Team','GP','MIN','FGM','FGA','FG%','3PM','3PA','3P%','FTM','FTA','FT%','TOV','PF','ORB','DRB','REB','AST','STL','BLK','PTS']
    statsheet = []
    stat_dict = {}
    result = []
    flag = 1
    while flag != 0:
        for i in range(1,int(pages)):
            # get page for parsing
            webpage = url + str(i) + section
            print('opening {}{}{}'.format(url,i,section))
            parse_str = requests.get(webpage)

            # check response
            if parse_str.status_code !=200:
                # something went wrong
                raise apiError('GET /stats/ {}'.format(parse_str.status_code))
                flag = 0
                break

            # BS4 does the magic
            soup = BeautifulSoup(parse_str.text, "lxml")

            # this is very specific to the pages we're scraping.
            if soup("tbody"):
                soup_str = soup("tbody")[0].find_all('tr')

                # here i'm taking the string and slicing and dicing into a list
                for isec, row in enumerate(soup_str):
                    cols = row.findChildren(recursive=True)
                    cols = [ele.text.strip().replace(",", "") for ele in cols]
                    stat_line = str(cols).replace("u'", "").replace("'", "").replace("[", "").replace("]", "")
                    stat_list = stat_line.split(',')

                    # enumerate through the stat_list we scrapped from this webpage
                    for istat, stat in enumerate(stat_list):

                        # some fields were duds, so I labelled them 'omit' so we can skip them in our output
                        if header_list[istat] != 'omit':
                            stat_dict[header_list[istat].replace('%','P')] = stat.strip()

                    # create player from stat dictionary and append to list
                    result.append(Player(stat_dict))
            else:
                flag = 0
                break

        # returning  list of player objects
        return result

def print_all_stats(stat_obj):
    for i, player in enumerate(stat_obj):
        print(player[i])

def print_player_stats(player):
    print('{} has racked up {} points, {} assists, {} rebounds, and {} turnovers.  His pool value to date is: {}'.format(player.name, player.pts, player.ast, player.reb, player.tov, player.get_value()))

def create_pool_sim(draft_def):
    for owner, data in draft_def.items():
        print(owner)
        for player, pos in data.items():
            print('{} : {}'.format(player, pos))

def create_pool(draft_def, draft_players):
    owner_pool = []
    for owner, data in draft_def.items():
        owner_pool.append(Owner(owner))
        for player, pos in data.items():
            #print('{} : {}'.format(player, pos))
            if pos.lower() == 'c':
                print('adding {} @ {} for {}'.format(player, pos, owner_pool[-1].name))
                owner_pool[-1].add_center(find_player(player, draft_players))
                #owner_pool[-1].list_centers()
            elif pos.lower() == 'f':
                print('adding {} @ {} for {}'.format(player, pos, owner_pool[-1].name))
                owner_pool[-1].add_forward(find_player(player, draft_players))
            elif pos.lower() == 'g':
                print('adding {} @ {} for {}'.format(player, pos, owner_pool[-1].name))
                owner_pool[-1].add_guard(find_player(player, draft_players))
            else:
                print('exception caught')

def ask_for_stats(all_stats):
    i_should_ask = True
    while i_should_ask:
        user_input = raw_input('enter player name (type :q to quit): ')
        if user_input == ':q':
            i_should_ask = False
        else:
            print_player_stats(find_player(user_input,all_stats))

def create_rosters():
    # SET-UP LEAGUE
    draft = {
            'Chris':{'Brook Lopez':'C',
                'Dwight Howard':'C',
                'Marcin Gortat':'C',
                'Blake Griffin':'F',
                'LeBron James':'F',
                'Tobias Harris':'F',
                'Wilson Chandler':'F',
                'Zach Randolph':'F',
                'Damian Lillard':'G',
                'Eric Bledsoe':'G',
                'George Hill':'G',
                'Jrue Holiday':'G',
                'Kemba Walker':'G'},
            'Ed':{'Clint Capela':'C',
                'Karl-Anthony Towns':'C',
                'Kevin Love':'C',
                'Aaron Gordon':'F',
                'Andrew Wiggins':'F',
                'JaMychal Green':'F',
                'Nikola Mirotic':'F',
                'Paul Millsap':'F',
                'Tim Hardaway Jr.':'F',
                'DeMar DeRozan':'G',
                'Elfrid Payton':'G',
                'John Wall':'G',
                'Ricky Rubio':'G'},
            'Eymard':{'Myles Turner':'C',
                'Nikola Jokic':'C',
                'Rudy Gobert':'C',
                'Draymond Green':'F',
                'Julius Randle':'F',
                'Otto Porter':'F',
                'Serge Ibaka':'F',
                'Ben Simmons':'G',
                'C.J. McCollum':'G',
                'Eric Gordon':'G',
                'James Harden':'G',
                'Jeremy Lin':'G',
                'Mike Conley':'G'},
            'Jay':{'Andre Drummond':'C',
                'Hassan Whiteside':'C',
                'Joel Embiid':'C',
                'Gordon Hayward':'F',
                'Jimmy Butler':'F',
                'Kelly Oubre Jr.':'F',
                'LaMarcus Aldridge':'F',
                'Norman Powell':'F',
                'Trevor Ariza':'F',
                'Devin Booker':'G',
                'Justin Holiday':'G',
                'Reggie Jackson':'G',
                'Russell Westbrook':'G'},
            'Jun':{'Jusuf Nurkic':'C',
                'Nikola Vucevic':'C',
                'Al Horford':'F',
                'Anthony Davis':'F',
                'Carmelo Anthony':'F',
                'Dario Saric':'F',
                'Ersan Ilyasova':'F',
                'Paul George':'F',
                'Chris Paul':'G',
                'Dennis Schroder':'G',
                'Gary Harris':'G',
                'Jeff Teague':'G',
                'Stephen Curry':'G'},
            'Rhon':{'DeMarcus Cousins':'C',
                'Jonas Valanciunas':'C',
                'Willie Cauley-Stein':'C',
                'Danilo Gallinari':'F',
                'Harrison Barnes':'F',
                'Kevin Durant':'F',
                'Khris Middleton':'F',
                'Kristaps Porzingis':'F',
                'Bradley Beal':'G',
                'DAngelo Russell':'G',
                'Klay Thompson':'G',
                'Kyrie Irving':'G',
                'Lonzo Ball':'G'},
            'Shawn':{'DeAndre Jordan':'C',
                'Enes Kanter':'C',
                'Marc Gasol':'C',
                'Brandon Ingram':'F',
                'Dirk Nowitzki':'F',
                'Giannis Antetokounmpo':'F',
                'Kawhi Leonard':'F',
                'Dwyane Wade':'G',
                'Goran Dragic':'G',
                'J.J. Redick':'G',
                'Kyle Lowry':'G',
                'Terrence Ross':'G',
                'Victor Oladipo':'G'}
            }

def main():

    # grab stats
    x = scrape_stats()
    # create_pool(draft,x)
    ask_for_stats(x)

    # TESTING

    # GET STATS
    '''
    print('top player: ', x[0].name, x[0].get_value())
    print('total players: ', len(x))
    #print_stats(x)
    y = find_player('towns', x)
    print(y.name)
    '''

    '''
    #
    # base URL "https://basketball.realgm.com/nba/stats/2018/Totals/Qualified/points/All/desc/"
    # end URL "/Regular_Season"

    # aws db connection
    db_host = 'db-cloudgeek.cl182ry29dun.ca-central-1.rds.amazonaws.com'
    db_name = 'chumpball'
    db_port = '3306'
    db_user = 'cguser'
    db_pswd = 'P!fja#hst68'

    # local db connection
    test_host = '127.0.0.1'
    test_name = 'chumpball'
    test_port = ''
    test_user = 'root'
    test_pswd = ''

    '''
