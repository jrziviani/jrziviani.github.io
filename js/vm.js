class processor
{
    constructor()
    {
        this.registers = new Array(3);
        this.memory = new Array(256);
        this.cmp_register = 0;

        this.program_space = 0;
        this.data_space = 128;
        this.video_space = 255;

        this.insn_pointer = 0;
        this.stack_pointer = 0;
    }

    get_register_by_name(name)
    {
        if (name == 'REG1') {
            return 0;
        }
        else if (name == 'REG2') {
            return 1;
        }
        else if (name == 'REG3') {
            return 2;
        }

        return undefined;
    }

    get_reg1()
    {
        return this.registers[0];
    }

    get_reg2()
    {
        return this.registers[1];
    }

    get_reg3()
    {
        return this.registers[2];
    }

    get_stack()
    {
        return this.memory.slice(this.data_space, this.data_space + 15);
    }

    get_video()
    {
        return this.memory[this.video_space];
    }

    get_stack_pointer()
    {
        return this.stack_pointer;
    }

    load_program(line)
    {
        if (this.program_space >= this.data_space) {
            return;
        }

        this.memory[this.program_space++] = line;
    }

    fetch()
    {
        if (this.insn_pointer >= this.program_space) {
            return undefined;
        }

        return this.memory[this.insn_pointer++];
    }

    run_step()
    {
        var insn = this.fetch();
        if (typeof insn == 'undefined') {
            return false;
        }

        return !this.decode_and_execute(insn);
    }

    run_step_back()
    {
        return false;
    }

    run()
    {
        while (this.run_step()) {}
    }

    get_program_counter()
    {
        return this.insn_pointer;
    }

    jump(to)
    {
        var address = to;
        var register = this.get_register_by_name(to);
        if (typeof register != 'undefined') {
            address = this.registers[register];
        }

        if (address < 0 || address >= this.data_space) {
            return;
        }

        this.insn_pointer = Number(address);
    }

    jump_if(to)
    {
        if (this.cmp_register == 0) {
            return;
        }

        var address = to;
        var register = this.get_register_by_name(to);
        if (typeof register != 'undefined') {
            address = this.registers[register];
        }
        address = Number(address);

        if (address < 0 || address >= this.data_space) {
            return;
        }

        this.insn_pointer = address;
    }

    ceq(regname)
    {
        var register = this.get_register_by_name(regname);
        if (typeof register == 'undefined') {
            return;
        }

        this.cmp_register = 0;
        if (this.registers[register] == 0) {
            this.cmp_register = 1;
        }
    }

    push(value)
    {
        var data = value;
        var register = this.get_register_by_name(value);
        if (typeof register != 'undefined') {
            data = this.registers[register];
        }

        this.memory[this.data_space + this.stack_pointer] = Number(data);
        this.stack_pointer++;
    }

    pop(regname)
    {
        var register = this.get_register_by_name(regname);
        if (typeof register == 'undefined') {
            return;
        }

        this.registers[register] = this.memory[this.data_space + this.stack_pointer - 1];
        this.stack_pointer--;
    }

    copy(regname, address)
    {
        address = Number(address);
        if (address < 0 || address >= this.data_space) {
            return;
        }

        var register = this.get_register_by_name(regname);
        if (typeof register == 'undefined') {
            return;
        }

        this.registers[register] = address;
    }

    add(reg_dest, a, b)
    {
        var dest = this.get_register_by_name(reg_dest);
        if (typeof dest == 'undefined') {
            return;
        }

        var value_a = a;
        var reg_a = this.get_register_by_name(a);
        if (typeof reg_a != 'undefined') {
            value_a = this.registers[reg_a];
        }

        var value_b = b;
        var reg_b = this.get_register_by_name(b);
        if (typeof reg_b != 'undefined') {
            value_b = this.registers[reg_b];
        }

        this.registers[dest] = Number(value_a) + Number(value_b);
    }

    sub(reg_dest, a, b)
    {
        var dest = this.get_register_by_name(reg_dest);
        if (typeof dest == 'undefined') {
            return;
        }

        var value_a = a;
        var reg_a = this.get_register_by_name(a);
        if (typeof reg_a != 'undefined') {
            value_a = this.registers[reg_a];
        }

        var value_b = b;
        var reg_b = this.get_register_by_name(b);
        if (typeof reg_b != 'undefined') {
            value_b = this.registers[reg_b];
        }

        this.registers[dest] = Number(value_a) - Number(value_b);
    }

    output(regname)
    {
        var register = this.get_register_by_name(regname);
        if (typeof register == 'undefined') {
            return;
        }

        this.memory[this.video_space] = this.registers[register];
    }

    decode_and_execute(command)
    {
        var decd = command.split(' ');
        var insn = decd[0];
        var exit = false;

        switch (insn) {
            case 'jump':
                this.jump(decd[1]);
                break;

            case 'jcmp':
                this.jump_if(decd[1]);
                break;

            case 'ceq':
                this.ceq(decd[1]);
                break;

            case 'copy':
                this.copy.apply(this, decd[1].split(','));
                break;

            case 'push':
                this.push(decd[1]);
                break;

            case 'pop':
                this.pop(decd[1]);
                break;

            case 'add':
                this.add.apply(this, decd[1].split(','));
                break;

            case 'sub':
                this.sub.apply(this, decd[1].split(','));
                break;

            case 'output':
                this.output(decd[1]);
                break;

            case 'halt':
                exit = true;
                break;

            default:
                exit = true;
                break;
        }

        return exit;
    }
}

var program = `copy REG3,4
push 5
push 3
jump 11
output REG1
copy REG3,9
push REG1
push 2
jump 11
output REG1
jump 26
pop REG1
pop REG2
push REG3
push REG2
sub REG1,REG1,1
ceq REG1
jcmp 22
push REG2
push REG1
copy REG3,22
jump 11
pop REG2
add REG1,REG1,REG2
pop REG3
jump REG3
halt`;

function init_vm()
{
    var vm = new processor();

    var lines = program.split('\n');
    for (var i = 0; i < lines.length; i++) {
        vm.load_program(lines[i]);
    }

    return vm;
}
