// GUI fixed sizes
const PROGRAM_FONT_SIZE = 12;
const PROGRAM_BOX_X = 100;
const PROGRAM_BOX_Y = 0;
const PROGRAM_PADDING_X = 10;
const PROGRAM_PADDING_Y = 7;

const PROGRAM_BACKGROUND_COLOR = '#eee';
const PROGRAM_TEXT_COLOR = '#000';

const REGISTER_WIDTH = 100;
const REGISTER_HEIGHT = 70;

const STACK_WIDTH = 150;
const STACK_HEIGHT = 300;

const MONITOR_WIDTH = 150;
const MONITOR_HEIGHT = 150;

const COMPONENT_BACKGROUND_COLOR = '#000';
const COMPONENT_TITLE_FONT = 'bold 14px Helvetica';
const COMPONENT_TITLE_COLOR = '#fff';
const COMPONENT_FONT = 'bold 14px Courier';
const COMPONENT_COLOR = '#a9d0f5';
const COMPONENT_HIGHLIGHT_COLOR = '#f7fe2e';
const COMPONENT_HIGHLIGHT_FONT = '10px Helvetica';

class box
{
    constructor(x, y, width, height)
    {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }
}

    var map_line = [ 1,  2,  3,  4,  6,  7,  8,  9, 10, 12,
                    13, 16, 17, 18, 19, 20, 21, 22, 23, 24,
                    25, 26, 28, 29, 30, 31, 34];


class vm_gui
{
    constructor(canvas)
    {
        this.ctx = canvas.getContext('2d');
        this.program_box = undefined;
        this.vm = init_vm();
        this.width = document.getElementById('canvas').offsetWidth;
        this.height = document.getElementById('canvas').offsetHeight;
    }

    shadow(value)
    {
        this.ctx.shadowColor = '#000';
        this.ctx.shadowBlur = value;
        this.ctx.shadowOffsetX = value;
        this.ctx.shadowOffsetY = value;
    }

    draw_program_box()
    {
        this.ctx.font = PROGRAM_FONT_SIZE + 'px Courier';

        var lines = v_program.split('\n');

        // calculate the program bounding box height
        var total_height = lines.length * (PROGRAM_FONT_SIZE + 6) + 2;

        // find the longest line width, this will define the bounding
        // box width
        var total_width = 0;
        for (var i = 0; i < lines.length; i++) {
            var width = this.ctx.measureText(lines[i]).width;
            if (width > total_width) {
                total_width = width;
            }
        }

        // setup the boundaries of the program box
        this.program_box = new box(PROGRAM_BOX_X,
                                   PROGRAM_BOX_Y,
                                   total_width + PROGRAM_PADDING_X,
                                   total_height + PROGRAM_PADDING_Y);

        // draw the box with background color
        this.ctx.beginPath();
        this.ctx.rect(this.program_box.x,
                      this.program_box.y,
                      this.program_box.width,
                      this.program_box.height);

        this.ctx.fillStyle = PROGRAM_BACKGROUND_COLOR;
        this.shadow(5);
        this.ctx.fill();
        this.shadow(0);

        // write the program text in the box
        this.ctx.fillStyle = PROGRAM_TEXT_COLOR;
        var y = PROGRAM_FONT_SIZE + PROGRAM_PADDING_Y;
        for (var i = 0; i < lines.length; i++) {
            this.ctx.fillText(lines[i], 108, y);
            y += PROGRAM_FONT_SIZE + 6;
        }
        this.ctx.closePath();
    }

    draw_nip(line)
    {
        this.ctx.beginPath();
        this.ctx.globalAlpha = 0.3;
        this.ctx.rect(0,
                      PROGRAM_PADDING_Y + (line * 18),
                      this.program_box.x + this.program_box.width,
                      17);
        this.ctx.fillStyle = COMPONENT_HIGHLIGHT_COLOR;
        this.ctx.fill();

        this.ctx.fillStyle = PROGRAM_TEXT_COLOR;
        this.ctx.font = COMPONENT_HIGHLIGHT_FONT;
        this.ctx.globalAlpha = 0.7;
        this.ctx.fillText('Instruction Pointer', 9, 18 + line * 18);
        this.ctx.globalAlpha = 1;
        this.ctx.closePath();
    }

    draw_registers(r1, r2, r3)
    {
        var registers = [r1, r2, r3];
        var x = this.program_box.x + REGISTER_WIDTH / 2;
        var placement = (this.program_box.width - this.program_box.x -
                        (REGISTER_WIDTH * registers.length)) / 2;

        this.ctx.beginPath();
        this.shadow(5);
        this.ctx.fillStyle = COMPONENT_BACKGROUND_COLOR;
        for (var i = 0; i < registers.length; i++) {
            this.ctx.rect(x,
                         this.program_box.height + 20,
                         REGISTER_WIDTH,
                         REGISTER_HEIGHT);
            this.ctx.fill();
            x += REGISTER_WIDTH + placement;
        }

        this.shadow(0);

        x = this.program_box.x + REGISTER_WIDTH / 2;
        for (var i = 0; i < registers.length; i++) {
            var regname = 'REG ' + Number(i + 1);
            var regval = String(registers[i]);
            if (regval === 'undefined') {
                regval = "x";
            }

            this.ctx.fillStyle = COMPONENT_TITLE_COLOR;
            this.ctx.font = COMPONENT_TITLE_FONT;
            var width = this.ctx.measureText(regname).width;
            this.ctx.fillText(regname,
                              x + ((REGISTER_WIDTH - width) / 2),
                              this.program_box.height + 35);

            this.ctx.fillStyle = COMPONENT_COLOR;
            this.ctx.font = COMPONENT_FONT;
            width = this.ctx.measureText(regval).width;
            this.ctx.fillText(regval,
                              x + ((REGISTER_WIDTH - width) / 2),
                              this.program_box.height + 65);

            x += REGISTER_WIDTH + placement;
        }

        this.ctx.closePath();
    }

    draw_stack(arr, next)
    {
        this.ctx.beginPath();
        this.ctx.rect(this.program_box.x + this.program_box.width + 25,
                     0,
                     STACK_WIDTH,
                     STACK_HEIGHT);
        this.ctx.fillStyle = COMPONENT_BACKGROUND_COLOR;
        this.shadow(5);
        this.ctx.fill();
        this.shadow(0);

        this.ctx.fillStyle = COMPONENT_TITLE_COLOR;
        this.ctx.font = COMPONENT_TITLE_FONT;
        var width = this.ctx.measureText('STACK').width;
        var x = this.program_box.x + this.program_box.width + 30;
        this.ctx.fillText('STACK',
                         x + (STACK_WIDTH - width) / 2,
                         15);

        this.ctx.fillStyle = COMPONENT_COLOR;
        this.ctx.font = COMPONENT_FONT;
        for (var i = 0; i < arr.length; i++) {
            width = this.ctx.measureText(arr[i]).width;
            if (typeof arr[i] == 'undefined') {
                continue;
            }
            this.ctx.fillText(arr[i],
                             x + (STACK_WIDTH - width) / 2,
                             18 * i + 40);
        }
        this.ctx.closePath();

        this.ctx.beginPath();
        this.ctx.globalAlpha = 0.4;
        this.ctx.rect(x - 5,
                     10 + next * 18,
                     STACK_WIDTH + 85,
                     14);
        this.ctx.fillStyle = COMPONENT_HIGHLIGHT_COLOR;
        this.ctx.fill();

        this.ctx.fillStyle = PROGRAM_TEXT_COLOR;
        this.ctx.globalAlpha = 0.7;
        this.ctx.font = COMPONENT_HIGHLIGHT_FONT;
        this.ctx.fillText('Stack Pointer',
                         x + STACK_WIDTH + 8,
                         20 + next * 18);
        this.ctx.globalAlpha = 1;
        this.ctx.closePath();
    }

    draw_monitor(data)
    {
        this.ctx.beginPath();
        this.ctx.rect(this.program_box.x + this.program_box.width + 25,
                     STACK_HEIGHT + 40,
                     MONITOR_WIDTH,
                     MONITOR_HEIGHT);
        this.ctx.fillStyle = COMPONENT_BACKGROUND_COLOR;
        this.shadow(5);
        this.ctx.fill();
        this.shadow(0);

        this.ctx.fillStyle = COMPONENT_TITLE_COLOR;
        this.ctx.font = COMPONENT_TITLE_FONT;
        var width = this.ctx.measureText('TERMINAL').width;
        var x = this.program_box.x + this.program_box.width + 30;
        this.ctx.fillText('TERMINAL',
                         x + (MONITOR_WIDTH - width) / 2,
                         STACK_HEIGHT + 56);

        if (typeof data == 'undefined') {
            this.ctx.closePath();
            return;
        }

        this.ctx.fillStyle = COMPONENT_COLOR;
        this.ctx.font = COMPONENT_FONT;
        width = this.ctx.measureText(data).width;
        this.ctx.fillText(data,
                          x + (MONITOR_WIDTH - width) / 2,
                          STACK_HEIGHT + 115);

        this.ctx.closePath();
    }

    run_step()
    {
        this.vm.run_step();
    }

    draw()
    {
        var reg1 = this.vm.get_reg1();
        var reg2 = this.vm.get_reg2();
        var reg3 = this.vm.get_reg3();
        var stk = this.vm.get_stack();
        var stk_ptr = this.vm.get_stack_pointer();
        var line = this.vm.get_program_counter();

        this.ctx.clearRect(0, 0, this.width, this.height);
        this.draw_program_box();
        this.draw_nip(map_line[line]);
        this.draw_registers(reg1, reg2, reg3);
        this.draw_stack(stk, stk_ptr + 1);
        this.draw_monitor(this.vm.get_video());
    }
}

var v_program = `     MAIN:
0x00 copy      REG3, @MAIN.RET.1   # copy return addr to REG3
0x01 push      5                   # push number 5 onto the stack
0x02 push      3                   # push number 3 onto the stack
0x03 jump      MULT                # jump to (call) MULT(5 * 3)
     MAIN.RET.1:
0x04 output    REG1                # print mult result (REG1)
0x05 copy      REG3, @MAIN.RET.2   # copy return addr to REG3
0x06 push      REG1                # push REG1 value
0x07 push      2                   # push number 2 onto the stack
0x08 jump      MULT                # jump to (Call) MULT(result * 2)
     MAIN.RET.2:
0x09 output    REG1                # print mult result (REG1)
0x0A jump      EXIT                # stop execution

     MULT:
0x0B pop       REG1                # pop param 2 from stack to REG1
0x0C pop       REG2                # pop param 1 from stack to REG2
0x0D push      REG3                # push return addr onto the stack
0x0E push      REG2                # push REG2 (param 2) onto the stack
0x0F sub       REG1, REG1, 1       # decrement 1 from REG1 (param 1)
0x10 ceq       REG1                # compare if REG1 == 0 and set cmp flag
0x11 jcmp      MULT.END            # jump to MULT.END IF cmp flag is 1
0x12 push      REG2                # push REG2 onto the stack
0x13 push      REG1                # push REG1 onto the stack
0x14 mov       REG3, @MULT.END     # copy MULT.END return addr to REG3
0x15 jump      MULT                # call MULT again
     MULT.END:
0x16 pop       REG2                # pop from stack to REG2
0x17 add       REG1, REG1, REG2    # REG1 = REG1 + REG2
0x18 pop       REG3                # pop from stack to REG3
0x19 jump      REG3                # jump to return addr

     EXIT:
0x1A halt`;
