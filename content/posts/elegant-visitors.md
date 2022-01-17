---
title: "Elegant Visitors"
tags: ['C++', 'design patterns', 'OO']
date: 2017-12-03T17:09:28-08:00
draft: false
author: "Jose R. Ziviani"
showToc: true
TocOpen: false
comments: false
disableHLJS: true
searchHidden: true
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
summary: "Exploring the powerful visitor design pattern."
---
The visitor design pattern is a powerful programming pattern that I was not fundamentally aware. I knew the pattern, I had seen code examples using that pattern but I hadn't realized how powerful and elegant it is. I confess that I overlooked at it, but the description in sites/blogs/book usually makes it confusing to me. Nonetheless, I should have gone through the practical aspects of it instead of **just** reading the concepts...lessons learned!

### Traversing the Object Hierarchy

It's simply there in the [wikipedia](https://en.wikipedia.org/wiki/Visitor_pattern):

> Clients traverse the object structure and call a dispatching operation accept(visitor) on an element — that "dispatches" (delegates) the request to the "accepted visitor object". The visitor object then performs the operation on the element ("visits the element").

But, I only **really** read it after read the **excellent** [Crafting Interpreters](http://www.craftinginterpreters.com/) book.

The [Crafting Interpreters](http://www.craftinginterpreters.com/) uses the visitor pattern to implement the [abstract syntax tree (AST)](https://en.wikipedia.org/wiki/Abstract_syntax_tree) where the object hierarchy (which was created during the parsing phase) is the tree. Clients (be it an interpreter, a compiler, or even something to print the AST) can traverse the tree hierarchy by "visiting" the objects. Cool.

### Coding

This code is obviously based on the referred book but I only wrote parts to highlight the visitor pattern.

{{< highlight cpp "linenos=inline">}}
    class expression_t
    {
    public:
        virtual int accept(expression_visitor &v) = 0;
        virtual ~expression_t() {}
    };
    using expression = unique_ptr<expression_t>;
    
    class type_number : public expression_t
    {
        int value_;
    
    public:
        type_number(int v) :
            value_(v)
        {
        }
    
        type_number(string v) :
            value_(stoi(v))
        {
        }
    
        int get() const
        {
            return value_;
        }
    
        int accept(expression_visitor &v)
        {
            return v.visit_number(*this);
        }
    };
    
    class binary_expression : public expression_t
    {
        expression left_;
        expression right_;
        char oper_;
    
        public:
        binary_expression(expression l,
                          expression r,
                          char o) :
            left_(move(l)),
            right_(move(r)),
            oper_(o)
        {
        }
    
        expression_t *left()
        {
            return left_.get();
        }
    
        expression_t *right()
        {
            return right_.get();
        }
    
        char operation() const
        {
            return oper_;
        }
    
        int accept(expression_visitor &v)
        {
            return v.visit_binary(*this);
        }
    };
{{< / highlight >}}

Nothing special here. An abstract class with a pure virtual method called `accept()` and two classes implementing it. One represents numbers, other represents binary expressions like 3 \* 5. The `accept()` simply calls a method from the visitor passing the **instance** of itself as argument.

{{< highlight cpp "linenos=inline">}}
    class expression_visitor
    {
    public:
        virtual int  visit_number(type_number &v) = 0;
        virtual int visit_binary(binary_expression &v) = 0;
        virtual ~expression_visitor();
    };
    
    class interpreter : public expression_visitor
    {
        int visit_number(type_number &n)
        {
            return n.get();
        }
    
        int visit_binary(binary_expression &b)
        {
            int left = evaluate(b.left());
            int right = evaluate(b.right());
    
            switch (b.operation()) {
                case '+':
                    return left + right;
                    break;
    
                case '-':
                    return left - right;
                    break;
    
                case '*':
                    return left * right;
                    break;
    
                case '/':
                    return left / right;
                    break;
            }
    
            throw exception();
        }
    
        int evaluate(expression_t *e)
        {
            return e->accept(*this);
        }
    };
{{< / highlight >}}

Now, the visitor. The interpreter implements the visitor, giving meaning to each object that it needs to visit. Note that `visit_number()` returns the value stored in `type_number` and `visit_binary()` evaluates both `left()` and `right()` expressions - that can hold either `type_number` or other `binary_expression`. In other words, `visit_binary()` be called recursively until it finds a `type_number`. Isn't it beautiful and elegant?

![visitor diagram](/visitor_diagram.png)

### Full code listing

Here is the full code listing:

{{< highlight cpp "linenos=inline">}}
    #include <iostream>
    #include <string>
    #include <memory>
    #include <sstream>
    
    using namespace std;
    
    class type_number;
    class type_string;
    class binary_expression;
    class unary_expression;
    
    class expression_visitor
    {
    public:
        virtual int  visit_number(type_number &v) = 0;
        virtual int visit_binary(binary_expression &v) = 0;
        virtual ~expression_visitor() {}
    };
    
    class expression_t
    {
    public:
        virtual int accept(expression_visitor &v) = 0;
        virtual ~expression_t() {}
    };
    using expression = unique_ptr<expression_t>;
    
    class type_number : public expression_t
    {
        int value_;
    
    public:
        type_number(int v) :
            value_(v)
        {
        }
    
        type_number(string v) :
            value_(stoi(v))
        {
        }
    
        int get() const
        {
            return value_;
        }
    
        int accept(expression_visitor &v)
        {
            return v.visit_number(*this);
        }
    };
    
    class binary_expression : public expression_t
    {
        expression left_;
        expression right_;
        char oper_;
    
        public:
        binary_expression(expression l,
                          expression r,
                          char o) :
            left_(move(l)),
            right_(move(r)),
            oper_(o)
        {
        }
    
        expression_t *left()
        {
            return left_.get();
        }
    
        expression_t *right()
        {
            return right_.get();
        }
    
        char operation() const
        {
            return oper_;
        }
    
        int accept(expression_visitor &v)
        {
            return v.visit_binary(*this);
        }
    };
    
    class interpreter : public expression_visitor
    {
        int visit_number(type_number &n)
        {
            return n.get();
        }
    
        int visit_binary(binary_expression &b)
        {
            int left = evaluate(b.left());
            int right = evaluate(b.right());
    
            switch (b.operation()) {
                case '+':
                    return left + right;
                    break;
    
                case '-':
                    return left - right;
                    break;
    
                case '*':
                    return left * right;
                    break;
    
                case '/':
                    return left / right;
                    break;
            }
    
            throw exception();
        }
    
        int evaluate(expression_t *e)
        {
            return e->accept(*this);
        }
    
        public:
        void compute(expression x)
        {
            cout << evaluate(x.get()) << endl;
        }
    };
    
    class parser
    {
        private:
        expression parse(string s)
        {
            stringstream tokens;
            tokens << s;
            return parse_add_sub(tokens);
        }
    
        expression parse_add_sub(stringstream &tk)
        {
            expression left = parse_mult_div(tk);
    
            while (tk.peek() == '+' || tk.peek() == '-') {
                char operation = tk.get();
                expression right = parse_mult_div(tk);
                left = make_unique<binary_expression>(move(left),
                                                      move(right),
                                                      operation);
            }
    
            return left;
        }
    
        expression parse_mult_div(stringstream &tk)
        {
            expression left = parse_number(tk);
    
            while (tk.peek() == '*' || tk.peek() == '/') {
                char operation = tk.get();
                expression right = parse_number(tk);
                left = make_unique<binary_expression>(move(left),
                                                      move(right),
                                                      operation);
            }
    
            return left;
        }
    
        expression parse_number(stringstream &tk)
        {
            string sval;
            tk >> sval;
            int value = 0;
    
            try {
                value = stoi(sval);
            }
            catch (invalid_argument &e) {
                cerr << "expected a number, found " << sval << endl;
                exit(1);
            }
            catch (out_of_range &e) {
                cerr << "number " << sval << " overflows an integer storage" << endl;
                exit(1);
            }
    
            while (tk.peek() == ' ')
                tk.get();
    
            return make_unique<type_number>(value);
        }
    
        public:
        expression parse_it(string s)
        {
            return parse(s);
        }
    };
    
    int main()
    {
        interpreter it;
        parser p;
    
        while (true) {
            string line;
    
            getline(cin, line);
            if (line == "quit")
                break;
    
            it.compute(p.parse_it(line));
        }
        return 0;
    }
{{< / highlight >}}

{{< highlight console >}}
    g++ -std=c++14 -Wall -Wextra -g visitors.cpp -o visitors
    % ./visitors
    3 * 5 + 8 - 3
    20
    15 * 80 / 2 + 3 * 8
    624
    quit
{{< / highlight >}}
