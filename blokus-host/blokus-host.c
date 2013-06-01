/*
    ICFPT 2013 Design Competition test (and will be the host) program 

    Platform: 
      - Developed on FreeBSD 8.3 (amd64).
      - On other platforms, 
          - modify /dev entries in serial_dev[]
          - init_serial() may be have to be modified
      - PATCHES FOR OTHER PLATFORM ARE WELCOME!

    Usage (First move player x Second move player):
      - stdin x stdin : to learn 4-letter code 
          ./blokus-host
          ./blokus-host -t   (show list of available tiles)
          ./blokus-host -p   (show the shape of placed tile)
          ./blokus-host -h   (show hint: but usually not a good move :p )

      - serial port 0 x stdin : FPGA board moves first, then human
          ./blokus-host -1

      - stdin x serial port 0 : Human moves first, then FPGA board
          ./blokus-host -2

      - serial port 0 x serial port 1 : FPGA board vs FPGA board
          ./blokus-host -3 (but still NOT works)

      To interrupt this program in interactive mode, press Ctrl+D (not Ctrl+C).
      This will transmit "9" to the serial port to make the game over.

    Revision history:
      - Mar.12, 2013: First version released.
      - Mar.13, 2013: Requires "0000" on serial port.
                      Proper EOF handling on console.
      - Mar.19, 2013: Cygwin compatibility.
                      Protocol fix (FPGA sends 4-letter code XXXX, 
                                    but not 3XXXX!)
      - Mar.26, 2013: Follow-up to protocol 0.9.
      - Air.02, 2013: 'p' tile fix
 
    License:
      - Yasunori Osana <osana@eee.u-ryukyu.ac.jp> wrote this file.
      - This file is provided "AS IS" in the beerware license rev 42.
        (see http://people.freebsd.org/~phk/)

    Acknowledgements:
      - Cygwin compatibility provided by Prof. Akira Kojima 
        at Hiroshima city university
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <fcntl.h>
#include "pieces.h"
#include "rotate.h"

#define BORDER 3

#define TRUE (1==1)
#define FALSE (!TRUE)

#define PIECE_ALREADY_PLACED -1
#define GRID_ALREADY_OCCUPIED -2
#define SHARES_EDGE -3
#define MUST_SHARE_VERTEX -4
#define MUST_COVER_FIRST_PLACE -5

#ifdef __CYGWIN__
const char* serial_dev[2] = { "/dev/com3", "/dev/com3" }; // cygwin
#else
const char* serial_dev[2] = { "/dev/cuaU0", "/dev/cuaU1" };
#endif


int serial_fd[2];
struct termios oldtio[2], tio[2];

int board[16][16];
int available[2][21];

char p1move1[5];

int show_board_status = TRUE;         // -b
int show_placed_tile = FALSE;         // -p
int show_available_tiles = FALSE;     // -t
int show_hint = FALSE;                // -h
int on_serial = 0;                    // -1, -2, -3

typedef struct {
  int x;
  int y;
  int piece;
  int rotate;
} move;

void show_board(){
  int i, x, y;
  if (show_available_tiles){
    printf("----------------- Available Tiles -----------------\n");
    printf("         ");
    for(i=0; i<21; i++) printf(" %c", 'a'+i); printf("\n");
    printf("Player 1:");
    for(i=0; i<21; i++) printf(" %d", available[0][i]); printf("\n");
    printf("Player 2:");
    for(i=0; i<21; i++) printf(" %d", available[1][i]); printf("\n");
  }

  if (show_board_status){
    printf("---------------------- Board ----------------------\n  ");
    for(x=0; x<16; x++)
      printf(" %c", ((x<10) ? x+'0' : x+'a'-10));
    printf("\n");
    for(y=0; y<16; y++){
      printf(" %c", ((y<10) ? y+'0' : y+'a'-10));
      for(x=0; x<16; x++){
        printf(" %c", ( board[y][x] == 0 ? ' ' : board[y][x] < 3 ? board[y][x]+'0' : '+'));
      }
      printf("\n");
    }
  }
  printf("---------------------------------------------------\n");
  fflush(stdout);
}

int check_code(char* code){
  char c;

  // pass is a valid code!
  if(code[0]=='0' && code[1]=='0' && code[2]=='0' && code[3]=='0') return TRUE;

  c=code[0];
  if(! (('0'<=c && c<='9') || ('a'<= c && c<='e')) ) return FALSE;

  c=code[1];
  if(! (('0'<=c && c<='9') || ('a'<= c && c<='e')) ) return FALSE;

  c=code[2];
  if(! ('a'<= c && c<='u') ) return FALSE;

  c=code[3];
  if(! ('0'<= c && c<='7') ) return FALSE;

  return TRUE;
}

move decode_code(char* code){
  // code must be valid!
  move m;
  char c;

  c=code[0];
  if('0'<=c && c<='9') m.x = c-'0';
  if('a'<=c && c<='e') m.x = c-'a'+10;

  c=code[1];
  if('0'<=c && c<='9') m.y = c-'0';
  if('a'<=c && c<='e') m.y = c-'a'+10;

  c=code[2];
  m.piece = c-'a';

  c=code[3];
  m.rotate = c-'0';

  if (show_placed_tile){
    int x,y;
    printf("------------------ Tile Pattern -------------------\n");

    printf("x: %d, y: %d, piece: %d, rotate: %d\n", m.x, m.y, m.piece, m.rotate);

    for(y=0; y<5; y++){
      for(x=0; x<5; x++){
        printf("%d ", pieces[m.piece][0][rotate[m.rotate][y][x]]);
      }
      printf("\n");
    }
  }

  return m;
}


int cheat(int player, int turn, char * code){
  move m;
  for (m.y=1; m.y<=15; m.y++){
    for (m.x=1; m.x<15; m.x++){
      for (m.piece=0; m.piece<21; m.piece++){
        for(m.rotate=0; m.rotate<8; m.rotate++){
          if(check_move(player, turn, m) == 0){
            if (show_hint){
              sprintf(code, "%c%c%c%c\n", 
                     ((m.x<10) ? m.x+'0' : m.x+'a'-10),
                     ((m.y<10) ? m.y+'0' : m.y+'a'-10),
                     m.piece+'a', m.rotate+'0');
            }
            return TRUE;
          }
        }
      }
    }
  }
  return FALSE;
}


char* prompt(int p, char* code, char* prev_code, int must_pass, int turn){
#ifdef DEBUG
  printf("turn %d\n", turn);
#endif
  
  if ( (on_serial == 0) ||
       (on_serial == 1 && p == 2) ||
       (on_serial == 2 && p == 1) ){ 
    // interactive
    if (must_pass){
      printf("(not asking move on console)\n");
      strcpy(code, "0000");
      return code;
    } else {
      printf("Player %d:", p);

      fgets(code, 6, stdin);
	  if(code[0] == '\n')
		cheat(p, turn, code);

      if(feof(stdin)){
	code[0] = 0;
	return NULL;
      }

      code[strlen(code)-1] = 0;
      return code;
    }
  } else {
    // serial
    char prompt_buf[10];
    char code_buf[10];
    int port;
    int got = 0;

    if(prev_code[0] == 0) printf("no prev code\n");
    else printf("prev code = %s\n", prev_code);

    port = (on_serial == 3) ? p-1 : 0;

    switch(turn+1){
    case 1: strcpy(prompt_buf, "25"); break;
    case 2: strcpy(prompt_buf, "2A"); break;
    case 4: snprintf(prompt_buf, 10, "4%s%s", p1move1, prev_code); break;
    default: snprintf(prompt_buf, 6, "3%s", prev_code);
    }

    printf("serial prompt string: %s (%d bytes)\n", 
	   prompt_buf, (int)strlen(prompt_buf));

    write(serial_fd[port], prompt_buf, strlen(prompt_buf));
    
    do {
      int bytes;
      bytes = read(serial_fd[port], &code_buf[got], 4-got);
      got += bytes;
    } while(got < 4);
    code_buf[4] = 0;
    strcpy(code, code_buf);
    printf("(got from serial %d: %s)\n", port, code);
    return code;
  }
  
  return NULL;
}

void do_pass(int p, char* code, char* prev_code, int turn){
  do { 
    prompt(p, code, prev_code, TRUE, turn);
    strcpy(prev_code, code);
  } while (strcmp("0000", code) != 0);
}

int check_move(int player, int turn, move m){
  //  printf("check_move: player %d, turn %d\n", player, turn);
  int c, r, x, y, x_offset, y_offset;
    
  c = m.piece;
  r = m.rotate;
  x_offset = m.x-2;
  y_offset = m.y-2;
    
  // Check availability
  if(available[player-1][c] == 0){
    return PIECE_ALREADY_PLACED;
  }

  // No piece on already occupied grid
  for(y=0; y<5; y++){
    for(x=0; x<5; x++){
      int b;
      b = pieces[c][0][rotate[r][y][x]];
      if (b==1){
        if (board[y_offset+y][x_offset+x] != 0 ||
            y_offset+y < 0 || 15 < y_offset+y ||
            x_offset+x < 0 || 15 < x_offset+x
            ){
          return GRID_ALREADY_OCCUPIED;
        }
      }
    }
  }

  // New piece can't share the edge
  for(y=0; y<5; y++){
    for(x=0; x<5; x++){
      int b;
      b = pieces[c][0][rotate[r][y][x]];
      if (b==1){
        int xx, yy;
        xx = x_offset+x;
        yy = y_offset+y;
        if (board[yy][xx-1] == player || board[yy][xx+1] == player ||
            board[yy-1][xx] == player || board[yy+1][xx] == player ){
          return SHARES_EDGE;
        }
      }
    }
  }

  // must share the vertex
  if(turn >= 2){
    int got_it = FALSE;
    for(y=0; y<5; y++){
      for(x=0; x<5; x++){
        int b;
        b = pieces[c][0][rotate[r][y][x]];
        if (b==1){
          int xx, yy;
          xx = x_offset+x;
          yy = y_offset+y;
          if (board[yy-1][xx-1] == player || board[yy+1][xx-1] == player ||
              board[yy-1][xx+1] == player || board[yy+1][xx+1] == player){
            got_it = TRUE;
          }
        }
      }
    }
    if(!got_it){
      return MUST_SHARE_VERTEX;
    }
  } else {
    // first 2 moves must cover (5,5) or (a,a)
    if( ! ((3<= m.x && m.x <= 7 && 3 <= m.y && m.y <= 7 &&
            pieces[c][0][rotate[r][ 5-y_offset][ 5-x_offset]]==1 ) ||
           (8<= m.x && m.x <= 12 && 8 <= m.y && m.y <= 12 &&
            pieces[c][0][rotate[r][10-y_offset][10-x_offset]]==1 )))
      return MUST_COVER_FIRST_PLACE;
  }

  return 0;
}

void show_error(int e){
  switch(e){
  case PIECE_ALREADY_PLACED:
    printf("INVALID MOVE! (the piece is already placed)\n");
    break;
  case GRID_ALREADY_OCCUPIED:
    printf("INVALID MOVE! (move on where already occupied)\n");
    break;
  case SHARES_EDGE:
    printf("INVALID MOVE! (shares edge)\n");
    break;
  case MUST_SHARE_VERTEX:
    printf("INVALID MOVE! (must share vertex)\n");
    break;
  case MUST_COVER_FIRST_PLACE:
    printf("INVALID MOVE! (first 2 moves must cover (5,5) or (a,a))\n");
    break;
  }
}

int check_possibility(int player, int turn){
  move m;

  for (m.y=1; m.y<=15; m.y++){
    for (m.x=1; m.x<15; m.x++){
      for (m.piece=0; m.piece<21; m.piece++){
        for(m.rotate=0; m.rotate<8; m.rotate++){
          if(check_move(player, turn, m) == 0){
            if (show_hint){
              printf("First-found possible move: %c%c%c%c\n", 
                     ((m.x<10) ? m.x+'0' : m.x+'a'-10),
                     ((m.y<10) ? m.y+'0' : m.y+'a'-10),
                     m.piece+'a', m.rotate+'0');
            }
            return TRUE;
          }
        }
      }
    }
  }
  return FALSE;
}


int next_player(player){
  if(player == 1) return 2;
  return 1;
}

int remaining_size(player){ // player 1 or 2 (not 0 or 1)
  int i, a=0;
  for(i=0; i<21; i++)
    a += available[player-1][i] * piece_sizes[i];

  return a;
}

void init_serial(){
  int p;
  int ports = 1;

  //  const char flush_code[11] = "9999999999";
  const char init_code[2] = "0";
  char team_id[4];
  int got;

  if (on_serial == 0) return;
  if (on_serial == 3) ports = 2;
  
  for (p=0; p<ports; p++){
	  printf("port %d.", p);
    serial_fd[p] = open(serial_dev[p], O_RDWR | O_NOCTTY);
    if (serial_fd[p] < 0 ) {
      perror("open serial failed lol! ");
      exit(-1);
    }
    
    tcgetattr(serial_fd[p], &oldtio[p]); // backup port settings
    tcflush(serial_fd[p], TCIOFLUSH);
  
    memset(&tio[p], 0, sizeof(tio[p]));
    cfsetispeed(&tio[p], 115200 );//
    cfsetospeed(&tio[p], 115200); //115200
    tio[p].c_cflag |= CS8; // 8N1
    tio[p].c_cflag |= CLOCAL; // local connection, no modem control
    tio[p].c_cflag |= CREAD;

    tcsetattr(serial_fd[p], TCSANOW, &tio[p]);
    tcflush(serial_fd[p], TCIOFLUSH);

    // flush 
    /*
    write(serial_fd[p], flush_code, strlen(flush_code));
    */

    write(serial_fd[p], init_code, strlen(init_code));

    got = 0;
    do {
      int bytes;
      bytes = read(serial_fd[p], &team_id[got], 3-got);
      got += bytes;
    } while(got < 3);
    team_id[3] = 0;
    printf("Team code on serial %d: %s\n", p, team_id);
    
  }
}

void close_serial(){
  int p;
  int ports = 1;

  const char close_code[11] = "9999999999";

  if (on_serial == 0) return;
  if (on_serial == 3) ports = 2;
  
  printf("sending termination code to serial port(s).\n");

  for (p=0; p<ports; p++){
    write(serial_fd[p], close_code, 10);
    tcdrain(serial_fd[p]);
    tcsetattr(serial_fd[p], TCSANOW, &oldtio[p]);
  }
}

void usage(){
  printf("Command line options: \n" \
         "   -b: Hide board status\n" \
         "   -p: Show placed tile on move\n"\
         "   -t: Show available tiles\n"\
         "   -h: Show hint (for quick testplay)\n"\
         "   -1: First move player on serial port 0\n"\
         "   -2: Second move player on serial port 0\n"\
         "   -3: Players on serial port 0 and 1. (still does NOT work)\n"\
         ""
         );
}

int main(int argc, char* argv[]){
  int c, x, y, r, player, turn;
  char code[6], prev_code[6];

  int ch;
  while ((ch = getopt(argc, argv, "bpth123?")) != -1) {
    switch (ch) {
    case 'b': show_board_status = FALSE;  break;
    case 'p': show_placed_tile = TRUE; break;
    case 't': show_available_tiles = TRUE; break;
    case 'h': show_hint = TRUE; break;
    case '1': on_serial = 1; break; // player 1 on serial
    case '2': on_serial = 2; break; // player 2 on serial
    case '3': on_serial = 3; break; // both player on serial
    case '?':
    default:
      usage();
      return 0;
    }
  }

  init_serial();

  // ------------------------------
  // clear board & available pieces

  for(y=0; y<16; y++)
    for(x=0; x<16; x++)
      board[y][x] = 0;

  for(y=0; y<2; y++)
    for(x=0; x<21; x++)
      available[y][x] = 1;

  // setup board: border is already filled
  for(x=0; x<16; x++){
    board[ 0][ x] = BORDER;
    board[15][ x] = BORDER;
    board[ x][ 0] = BORDER;
    board[ x][15] = BORDER;
  }

#ifdef DEBUG
    // for test (some grids already occupied on start)
 for(y=7; y<=14; y++)
    for(x=11; x<=14; x++)
      board[y][x] = 2;

  for(y=11; y<=14; y++)
    for(x=7; x<=14; x++)
      board[y][x] = 2;
#endif


  // ------------------------------------------------------------
  // start!
   
  show_board();

  player = 1;
  turn = 0;
  prev_code[0] = 0;
  
  check_possibility(player, turn); // gives hint for first player

  while(prompt(player, code, prev_code, FALSE, turn)){
    move m;
    int e, x_offset, y_offset;
    if(code[0] == 0) break;  // ctrl+d

    // retry if invalid code
    while(!check_code(code)){
      prompt(player, code, prev_code, FALSE, turn);
      if(code[0] == 0) break;
    }
    if(code[0] == 0) break;  // ctrl+d
    if(prev_code[0] == 0) strcpy(p1move1, code);
    strcpy(prev_code, code);

    // pass
    if(strcmp(code, "0000") == 0){
      if(turn >= 2){
	player = next_player(player);
	turn++;
	continue;
      } else {
	printf("First move must not be a pass.\n");
	printf("Player %d lost the game.\n", player);
	break;
      }
    }

    m = decode_code(code);

    c = m.piece;
    r = m.rotate;
    x_offset = m.x-2;
    y_offset = m.y-2;
    

    if((e = check_move(player, turn, m)) != 0){
      show_error(e);
      printf("Player %d //lost the game.\n", player);
      break;
    }
  
    // OK, now place the move
    for(y=0; y<5; y++){
      for(x=0; x<5; x++){
        int b;
        b = pieces[c][0][rotate[r][y][x]];
        if (b==1)
          board[y_offset+y][x_offset+x] = player;
      }
    }
    available[player-1][c] = 0;

    if(remaining_size(player)==0){
        printf("Player %d won the game, since the player has no more pieces.\n",
               player);
        break;
    }
  
    // show the board & next player
    show_board();
    player = next_player(player);
    turn++;

    // check whether possible move is available or not
    if(!check_possibility(player, turn)){
      printf("Player %d has no more possible move.\n", player);
      do_pass(player, code, prev_code, turn);
      
      player = next_player(player);
      turn++;
      if(!check_possibility(player, turn)){
        int a1, a2;
        printf("Both players have no more possible move.\n");
	do_pass(player, code, prev_code, turn);
	
        a1 = remaining_size(1);
        a2 = remaining_size(2);
        
        printf("Total remaining size: %d / %d.\n", a1, a2);
        if(a1 != a2)
          printf("Player %d won the game!\n", ( (a1<a2) ? 1 : 2 ) );
        else
          printf("Draw game.\n");
        break;
      }
    }
  }

  close_serial();
  return 0;
}

