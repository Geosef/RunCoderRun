__author__ = 'kochelmj'

import threading
import time
from pprint import pprint

from game import collectgame_algorithms, staticdata


class Game(object):

    MAXTURNS = 10
    MAXSCORE = 5

    def __init__(self, p1Thread, p2Thread, gameID, gamePref):
        p1Thread.index = 0
        p2Thread.index = 1
        self.gameID = gameID
        self.threads = [p1Thread, p2Thread]
        self.lock = threading.Lock()
        self.rematchLock = threading.Lock()
        self.currentTurn = 0
        self.currentMoves = {0:None, 1:None, 'alien':None}
        self.gridSize = 10
        self.maxMoves = 8
        self.full = False
        self.gameType = gamePref.get('gametype')
        self.difficulty = gamePref.get('difficulty')
        self.ready = [False, False]
        self.rematchBools = [False, False]

        self.setup(True)



    joinSuccess = \
        {
            'type': 'Join Game',
            'success': True
        }

    def setup(self, initial):
        self.currentTurn = 0
        if initial:
            pass
            # self.threads[0].sendData(self.joinSuccess)
            # self.threads[1].sendData(self.joinSuccess)


        gamesetup = staticdata.gamesetup

        time.sleep(4)

        for client in self.threads:
            client.sendData(gamesetup)

        locations = \
            {
                'p1': {'x': 1, 'y': 1},
                'p2': {'x': 10, 'y': 10},
                'alien': {'x': 5, 'y': 5}
            }
        alienMoves = collectgame_algorithms.calculateAlienMoves(self, locations)

        with self.lock:
            self.currentMoves['alien'] = alienMoves

            if self.checkFinish():
                self.finishTurn()

    def startGame(self, clientthread):
        with self.lock:
            self.ready[clientthread.index] = True
            pprint(self.ready)
            if all(self.ready):
                for client in self.threads:
                    client.sendData({'type': 'Start Game'})
                self.ready = [False for k in self.ready]



    def joinGame(self, p2Thread):
        self.full = True
        p2Thread.index = 1
        self.threads.append(p2Thread)
        playerJoined = \
            {
                'type': 'Player Joined',
                'username': p2Thread.userInfo.get('username')
            }
        self.threads[0].sendData(playerJoined)


    def submitMove(self, moves, thread):
        with self.lock:

            self.currentMoves[thread.index] = moves

            if self.checkFinish():
                self.finishTurn()


    def updateLocations(self, locations, scores):

        if self.currentTurn % 2 == 0:
            newItemLocations = collectgame_algorithms.calculateItemLocations(locations)
        else:
            newItemLocations = {'goldLocations': [], 'gemLocations': [], 'treasureLocations': []}

        alienMoves = collectgame_algorithms.calculateAlienMoves(self, locations)

        with self.lock:
            self.currentMoves['alien'] = alienMoves

            if self.checkFinish():
                self.finishTurn()

        if self.checkEndGame(scores):
            return

        for client in self.threads:
            client.sendData({'type': 'Update Locations', 'locations': newItemLocations})

    def checkEndGame(self, scores):
        if scores[0] >= self.MAXSCORE or \
        scores[1] >= self.MAXSCORE:
            print 'REACHED MAX SCORE'
            self.endGame(scores)
            return True
        if self.currentTurn >= self.MAXTURNS:
            print 'REACHED MAX MOVES'
            self.endGame(scores)
            return True
        return False

    def checkFinish(self):
        '''
        checks if all players have submitted their moves
        '''
        # pprint(self.currentMoves)
        for k in self.currentMoves.values():
            if k is None:
                return False
        return True

    def finishTurn(self, **kw):
        self.currentTurn = self.currentTurn + 1

        packet = \
            {
                'type': 'Run Events',
                'events': \
                    {
                        'p1': self.currentMoves[0],
                        'p2': self.currentMoves[1],
                        'alien': self.currentMoves['alien']
                    }
            }

        for client in self.threads:
            client.sendData(packet)

        for key in self.currentMoves.keys():
            self.currentMoves[key] = None

    def endGame(self, scores):
        packet = {'type': 'Game Over'}
        if scores[0] == scores[1]:
            packet['winner'] = 'None'
        elif scores[0] > scores[1]:
            packet['winner'] = self.threads[0].userInfo.get('username')
        else:
            packet['winner'] = self.threads[1].userInfo.get('username')

        for client in self.threads:
            client.sendData(packet)



    def rematch(self, client, packet):
        choice = packet.get('rematch')
        if not choice:
            index = (client.index + 1) // 2
            self.threads[index].sendData({'type': 'Rematch', 'rematch': False})
            self.cleanUp()
            return

        with self.rematchLock:
            self.rematchBools[client.index] = True
            if all(self.rematchBools):
                for client in self.threads: client.sendData({'type': 'Rematch', 'rematch': True})
                self.rematchBools = [False, False]
                self.setup(False)


    def cleanUp(self):
        '''
        Here in case we need to clean up any objects
        '''
        pass

    def refuse(self):
        '''
        Host refused to play client
        '''
        pass
        #TODO: implement kicking out peer

