
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <fcntl.h>

const char* serial_dev = "/dev/com3"; 
int serial_fd;
struct termios oldtio, tio;



char* sendString(char* aString){

	 //printf("send: %s\n", aString);

    char prompt_buf[10];
    char code_buf[10];
    int port;
    int got = 0;

    //if(prev_code[0] == 0) printf("no prev code\n");
    //else printf("prev code = %s\n", prev_code);

    //port = (on_serial == 3) ? p-1 : 0;

    //switch(turn+1){
    //case 1: strcpy(prompt_buf, "25"); break;
    //case 2: strcpy(prompt_buf, "2A"); break;
    //case 4: snprintf(prompt_buf, 10, "4%s%s", p1move1, prev_code); break;
    //default: snprintf(prompt_buf, 6, "3%s", prev_code);
    //}

    //printf("serial prompt string: %s (%d bytes)\n", 
	   //prompt_buf, (int)strlen(prompt_buf));
	printf("length:%d\n",strlen(aString));
    write(serial_fd, aString, strlen(aString));//prompt_buf, strlen(prompt_buf));strlen(aString)
    
    do {
      int bytes = 0;
      bytes = read(serial_fd, &code_buf[got],4-got);//
      got += bytes;
    } while(got < 4);
    code_buf[4] = 0;
    strcpy(aString, code_buf);
	//aString[1] = 0;
	//aString[2] = 0;
	//aString[3] = 0;
    printf("board: %s\n", aString);// aString);
    return aString;

}





char* prompt(char* code){
	//code = "------";
	printf("input code:");
	fgets(code, 7, stdin);

	if(feof(stdin)){
		code[0] = 0;
		return NULL;
	}

	code[strlen(code)-1] = 0;
	return code;
}






void init_serial(){
	printf("Starting Initialization of Serial Port Communication\n");
		
  int p;
  int ports = 1;

  //  const char flush_code[11] = "9999999999";
  const char init_code[2] = "AF";
  char team_id[4];
  int got;
  
  serial_fd = open(serial_dev, O_RDWR | O_NOCTTY);
	if (serial_fd < 0 ) {
		perror("open serial failed! ");
		exit(-1);
	}
    

    tcgetattr(serial_fd, &oldtio); // backup port settings
    tcflush(serial_fd, TCIOFLUSH);
  
    memset(&tio, 0, sizeof(tio));
    cfsetispeed(&tio,  115200);// 9600);
    cfsetospeed(&tio,  115200);//9600);
    tio.c_cflag |= CS8; // 8N1
    tio.c_cflag |= CLOCAL; // local connection, no modem control
    tio.c_cflag |= CREAD;

    tcsetattr(serial_fd, TCSANOW, &tio);
    tcflush(serial_fd, TCIOFLUSH);

    // flush 
    /*
    write(serial_fd[p], flush_code, strlen(flush_code));
    */

	//byte d = 
	char test[1] = "0";
	//char test[5] = "324SB";

	printf("length %d\n", strlen(test));
    write(serial_fd, test, strlen(test));//strlen(init_code));//test, 1);//

    got = 0;
//	printf("hello\n");

	//int bytes = 0;//read(serial_fd, &team_id, 1);
	// = 0;

    do {
      int bytes;
      bytes = read(serial_fd, &team_id[got], 3-got);//read(serial_fd, &team_id, 1);//
      got += bytes;
    } while(got < 3);
	
	//read(serial_fd, &team_id, 2-got);
	//read(serial_fd, &team_id, 2);
	//read(serial_fd, &team_id, 1);

	//team_id[1] = 0;
	//team_id[2] = 0;
    team_id[3] = 0;
    printf("%d bytes read, team code on serial : %s\n", got, team_id);
    
  
}

void close_serial(){
  int p;
  int ports = 1;

  const char close_code[11] = "9999999999";
  
  printf("sending termination code to serial port(s).\n");

  for (p=0; p<ports; p++){
    write(serial_fd, close_code, 10);
    tcdrain(serial_fd);
    tcsetattr(serial_fd, TCSANOW, &oldtio);
  }
}

int main(int argc, char* argv[]){
	
  int c, x, y, r, player, turn;
  char code[10] , prev_code[10];

  //printf("hello world\n");


  init_serial();
    //  return 0;
  while(prompt(code)){
	  
	  sendString(code);

	 //printf("%s\n", sendString(code));

  }


  close_serial();
  return 0;
}