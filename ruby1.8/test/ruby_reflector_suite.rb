require 'test/unit'
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'assert2'
#require File.dirname(__FILE__) + '/../lib/ruby_reflector'
require 'pathname'


class RubyReflectorTest < Test::Unit::TestCase
  include RubyNodeReflector  #  TODO  retire this module
  #include Assert_2_0

  def setup;  colorize(true);  end

  def test_all_op_codes
    [
      "def foo(x, y)\nreturn ( x + y )\nend\n",
      "def foo(x, *y)\nreturn ( x + y )\nend\n",         #  trailing star
      'foo(1, *[2, 3])',         #  trailing stars
      "def foo(x, *y, &block)\nreturn ( x + y )\nend\n", #  trailing star + block!
      'pretty = { "#<Proc" => "<Proc>" }.fetch("#<Proc", pretty)', # hashes_have_their_braces
      "class Foo\n\nBar = 42\nend\n",  # cdecl
      "class << self\n\nend\n",
      '( if ( [ "lambda", "proc" ].include?(exp) ) then  ' +
          'else ( exx = eval_intermediate(exp) ) end )',  #  hashes_have_their_brackets
      'hash = {}',  #  empty_hashes
      'loop{}',  #  eternal spin
      "def foo(x, y)\nx + o\nend\n",  #  transform_vcall
      "def foo(x, y)\nreturn\nend\n",  #  transform_return
      '[ 2, 3, 1, 1 ].sort().uniq()',  #  array_with_method
      "def foo(x, &block)\nyield\nblock.call()\nend\n",  #  transform_block_arg
      '( 0 .. size )',
      '( 0 ... size )',
      'lambda{|*a| p(a) }',  #  an argument splat inside goalposts! C-;
      "( while ya\nnil\nend )",
      "( until ya\nnil\nend )",
      "( for prime in ps\nnil\nend )",
      'x = C_ESC[[ ch ].pack("C")]',
      'C_ESC[[ ch ].pack("C")] = "x%02x" % ch',
      'C_ESC[42] ||= "x%02x" % ch',
      'Regexp.union(*C_ESC.keys())',
      'foo = [/#{ klass.name().sub(/.*::/, "").downcase() }/, klass]',
      'array = [19, 42]',
      '( if ( defined? ::Thang ) then ( puts("Got Thang") ) end )',
      'a, b, c, * = foo',
      "/\\A\#{ SEPARATOR_PAT }?\\z/",
      'prefix, *resolved = h[path]',
      'super()',
      'super(42)',
      'Bag = ::RSS::RDF::Bag',
      'self.Bag=(args[0])',
      'self.Bag ||= Bag.new()',
      'thang.Bag=(args[0])',
      'thang.Bag ||= Bag.new()',
      "def build_message(head, template = nil, *arguments)\n" +
        "template &&= template.chomp()\n" +
      "end\n",
      'a[i][j] -= ( ( a[k] )[j] ) * q',
      'ary[*[1]] = 0',
      "( case 1\nwhen 0\n:ng\nwhen 1\n42\n\nend )",
      'return [4, 2]',
      'END{ 42 }',
      'Proc.new(){ p(foo = 1) }',
      'q = {}',
      '@context.irb_path=(back_path)',
      '( @context.irb_path, back_path = path, @context.irb_path() )',
      '( back_path, @context.irb_path = path, @context.irb_path() )',
      'return *list',
      '( self.year, self.month, self.day = year, month, day )',
      'self[*@offset] = value',
      'argument_test(true, lambda{||})',
      'Tk::Tcllib::Tablelist_usingTile = true',
      "def foo(*)\nnil\nend\n",  #  we take anything, and we ignore it!
        #  ERGO  get rid of that nil?
      'x = [42, 43, 44]',      'x == [42, 43, 44]',
      '[ 42, 43, 44 ] == x',   '[ 42, 43, 44 ].foo() == x',
      '[ 42, 43, 44 ].foo()',  '( a, b, c = x )',
     # "begin\nrescue Whatever\ne = $!\nend\n",
     # "begin\nrescue Whatever, MeToo\ne = $!\nend\n",
     # "begin\nrescue Whatever\n\nend\n",
     # "begin\nrescue Whatever, MeToo\n\nend\n",
     # "begin\nrescue\ne = $!\nend\n",  # note that => e is syntactic sugar for e = $!
     # "begin\nrescue\ne = $!\nfoo\n\nend\n",
      "ex = foo rescue nil",
      "yield(@@x = {})",
      'self.class().accessor()',
      'alias yo dude',
      'alias $LAST_PAREN_MATCH $+',
      'self[$`] = i',
      'lambda{|| p("no") }',
      'lambda{|x, (y, z)| p("way!") }',
      '*a = nil',
      'Tk::Tcllib::Tablelist_usingTile = true',
#      'lambda{|x, (y, *z)| }',
# ERGO      'lambda{|(y, *z), x| }',
    ].each do |statement|
      assert{ reflect_string(statement) == statement }
      print '.'
    end
  end  #  TODO  both reflectors should pass this common stuff
  
  #  TODO  the 1.9 reflector should pass Ruby's native parsing tests

  def test_reflect_K_Sasada_s_rubynodes  # and props to her or him!
    rubynodes = Pathname.new(__FILE__).dirname + 'rubynodes/src/*.rb'

    Pathname.glob(rubynodes) do |_node_rb|
      @node_rb = _node_rb
      node_type = @node_rb.basename('.rb').to_s

      #  for dasgn see test_we_dont_do_plus_equals_like_that

      unless %w( dasgn ).include?(node_type)
        @contents = @node_rb.read

        assert_stderr //, 'silencio!' do
          once  = reflect_string(@contents)  #  ERGO repress warnings!
          twice = reflect_string(once)
          assert(node_type){ once == twice }
        end
      end
    end

  rescue
    puts @contents
    pp @node_rb
    raise
  end

  def test_bug_in_args_opcodes   #  can Ruby do this one??
    # colorize(:always)

    assert do
      reflect_string("def foo(x, y = 42)\nz = x + y\nend\n") ==
                     "def foo(x, y = 42, z = nil)\nz = x + y\nend\n"
    end  #  we can't distinguish passed args from scoped variables!

    assert do
      reflect_string("def post_splat(x, *splat)\nz = x + y\nend\n") ==
                     "def post_splat(x, *splat)\nz = x + y\nend\n"
    end

    assert do
      reflect_string("def post_block(x, &block)\nz = x + y\nend\n") ==
                     "def post_block(x, &block)\nz = x + y\nend\n"
    end

    assert do
      reflect_string("def splat_block(x, *y, &block)\nz = x + y\nend\n") ==
                     "def splat_block(x, *y, &block)\nz = x + y\nend\n"
    end
  end

  def test_op_asgn_or
    x = nil
    assert_equal 'x ||= 42', reflect_source{ x ||= 42 }
  end

  def test_broken_parens
    assert_equal '( ( ( node[:head] ).last() ) or ( [] ) ).each(){}',
      reflect_source{ (node[:head].last || []).each{} }
  end

  def test_violate_law_of_demeter
    assert_equal   'node[:body]',          reflect_source{ node[:body] }
    assert_equal '( node[:body] ).last()', reflect_source{ node[:body].last }

    assert_equal   '( node[:body] ).last().map(&:first)',
      reflect_source{ node[:body].last.map(&:first) }
  end

  def test_assign_splat
    assert_equal '( name, pops, rets, pushs1, pushs2 = ' +
                    '*calc_stack(insn, from, after, opops) )',
      reflect_source{
        name, pops, rets, pushs1, pushs2 =
          *calc_stack(insn, from, after, opops)
      }
  end

  def test_assign_arrays
    assert_equal '( a, b = 1, 2 )', reflect_source{ ( a, b = 1, 2 ) }
  end

  def test_array_bug
    assert_equal '42, 43, 44', reflect_source{ [ 42, 43, 44 ] }
  end

  def test_to_ary
    assert_equal '( a, b = foo )', reflect_source{ ( a, b = foo ) }
  end

  def test_mix_conditionals_and_matchers
    assert_equal "def we_b_op(zone)\n" +
                   "return ( ( ( zone[:mid] ) and " +
                     "( (not(/^[a-z]/i =~ ( zone[:mid] ).to_s())) ) ) )\n" +
                 "end\n",
      reflect_source{
        def we_b_op(zone)
          return zone[:mid] && zone[:mid].to_s !~ /^[a-z]/i
        end
      }
  end

  def test_eval_intermediate_paren_lists
    rf = RubyReflector.new(proc{})
    evals = rf.eval_intermediate_guarded('41, 42, 44').first
    assert{ evals.first == '[ 41, 42, 44 ]' }
      #  ERGO  only evaluate an intermediate if it contains a lower evaluation!
  end

  def test_collect_intermediate_evaluations
    x = 42
    y = 41
    rf = RubyReflector.new(proc{ x == y })
    assert{ rf.evaluations == [["x", 42, nil], ["y", 41, nil]] }
  end

  def test_evaluate_mashed_strings
    y = 1
    rf = RubyReflector.new(proc{ "4#{ 1 + y }" })
    eval_y, eval_mash = rf.evaluations
    assert{ eval_y    == ['y',               1,  nil] }
    assert{ eval_mash == ['"4#{ 1 + y }"', '42', nil] }
  end

  def test_insert_critical_newlines
    assert_equal "begin\n\nrescue \nensure\nnil\nend\n",
     reflect_source{
              begin
                #p 'begining'
              rescue
                #p 'rescuing'
              ensure
                #p 'ensuring'
              end }
  end

  def test_cvasgn
    assert_equal '@@cvasgn = @@froot_loop',
      reflect_source{ @@cvasgn = @@froot_loop }
  end

  def test_empty_goalposts
    assert_equal 'lambda{||}',      reflect_source{ lambda{ | |    } }
    assert_equal 'lambda{|| 42 }',  reflect_source{ lambda{ | | 42 } }
    assert_equal 'lambda{|*| 42 }', reflect_source{ lambda{ |*| 42 } }
    assert_equal 'lambda{|*|}',     reflect_source{ lambda{ |*|    } }
    assert_equal 'proc{|*|}',       reflect_source{   proc{ |*|    } }
    assert_equal 'proc{||}',        reflect_source{   proc{ | |    } }
    assert_equal 'proc{|| 42 }',    reflect_source{   proc{ | | 42 } }
    assert_equal 'proc{|*| 42 }',   reflect_source{   proc{ |*| 42 } }
  end  # lambda kind'a takes those seriously!

#  ERGO  learn what's Regexp.union do?

  def test_format_intermediate_evaluations
    colorize(false)
    x = 42
    rf = RubyReflector.new(proc{ (x + 21) == lambda{|z| z}.call(41) })
    report = rf.format_evaluations.split("\n")
    assert{ report[0] =~ /    x\s+--> 42/ }
    assert{ report[1] =~ /    \( x \+ 21 \)\s+--> 63/ }

    assert do
      report[2].index(
        "--? undefined local variable or method `z' for #<RubyReflectorTest" )
    end

    assert{ report[3] =~ /    lambda\{\|z\| z \}\s+--\> \<Proc\>/ }
    assert{ report[4] =~ /    lambda\{\|z\| z \}.call\(41\)\s+--> 41/ }
  end

  #############################################################
  ######## blocks

  def block_me(whatever = nil, &block) #:nodoc:
  end

  def test_unless_else
    assert{ reflect_string('( unless ( exx ) then ( why ) else ( zee ) end )') ==
              '( if ( exx ) then ( zee ) else ( why ) end )' }
  end   #  each time you write unless..else, Satan waterboards a kitten!

  def test_reflect_blocks
    x = 99
    y = 40
#  TODO p reflect{ lambda{ x + 1 }.call }

    assert_match /lambda\{|| x \+ 1 \}.call\(\)\t--> 100.*call.*100/m, reflect{ lambda{ x + 1 }.call }
    assert_match /proc\{|| y \+ 2 \}.*call\(\)\t--> 42/, reflect{ proc{ y + 2 }.call }
    assert_match /lambda\{|q| x \+ q \}.*call\(1\)\t--> 100.*q.*\?/m, reflect{ lambda{|q| x + q }.call(1) }
    assert_match "proc{ y + 2 }", reflect{ proc{ y + 2 }.call }

    if respond_to? :returning
      assert_match 'returning(42){}', reflect{ returning(42){} }
    end

    assert_match 'block_me{}', reflect{ block_me{} }
    assert_match 'block_me(42){}', reflect{ block_me(42){} }
    call_lambda = reflect{ lambda{|a, b| a + b }.call(40, 2) }
    assert_{ call_lambda.index('lambda{|a, b| a + b }') }
    assert_{ call_lambda.index("--? undefined local variable or method `a'") }
    assert_{ call_lambda.index("--? undefined local variable or method `b'") }
    assert_{ call_lambda =~ /lambda\{\|a, b\| a \+ b \}.call\(40, 2\)\s+-->/ }
    assert_{ call_lambda.index("lambda{|a, b| a + b }.call(40, 2)\t--> 42") }
  end

  def test_insert_critical_newlines
    assert_equal "( if ( 42 ) then ( foo << \" \"\n( if ( false ) then ( bar ) end )\n ) end )",
      reflect_source{
              if 42
                foo << ' '
                if false
                  bar()
                end
              end }
  end

  #############################################################
  ######## intermediate evaluations

  def test_cant_collect_intermediate_evaluations
    x = 42
    rf = RubyReflector.new(proc{ x == lambda{|z| z}.call(41) })
    x_eval, y_eval = rf.evaluations
    assert{ x_eval == ['x', 42, nil] }
    assert{ y_eval[0] == 'z' }
    assert{ y_eval[1].nil? }
    assert{ y_eval[2] =~ /undefined/ }
  end

  def test_dont_duplicate_intermediate_evaluations
    colorize(false)
    x = 42
    rf = RubyReflector.new(proc{ x + x })
    report = rf.format_evaluations.split("\n")
    assert{ report[0] =~ /    x\s+--> 42/ }
      deny{ report[1] }
  end

  #############################################################
  ######## regices

  def test_match3  #  note:  where's match3?
    q = 'foobar'
    r = /^foo(bar)$/
    assert_{ /foo(bar)/ =~ reflect{ q =~ r } }
    assert_{ $1 == 'bar' }
  end

  def test_reflect_regices
    x = '42'
    foo = Foo.new
    assert_match "/4/ =~ x\t--> 0", reflect{ /4/ =~ x }
    assert_match "/4/ =~ x\t--> 0", reflect{ /4/ =~ x }

    assert_match /\/4\/\ =~\ foo.bar\(\)\.to_s\(\)/m,
                    reflect{ /4/ =~ foo.bar.to_s }

    assert_match /foo.bar\(\)\.to_s\(\)\s+--> "42"/m,
                    reflect{ /4/ =~ foo.bar.to_s }
  end

  def test_escaped_regices
    assert{ reflect_source{ /hatch is \#/ } == "/hatch is \\#/" }
    assert{ reflect_source{ /solidus is \\/ } == "/solidus is \\\\/" }
    assert{ reflect_source{ /ticks are \`\'\"/ } == "/ticks are \\`\\'\\\"/" }
  end

  def test_evaluate_mashed_regices
    y = 1
    rf = RubyReflector.new(proc{ /4#{ 1 + y }/ })
    eval_y, eval_mash = rf.evaluations
    assert{ eval_y    == ['y',               1,  nil] }
    assert{ eval_mash == ['/4#{ 1 + y }/', /42/, nil] }
  end

  #############################################################
  ######## primitives

  LinkHogThrob = 'L7' #:nodoc:

  class Foo  #:nodoc:
    def bar;  42;  end
    def sym;  :bol;  end
    def inc(x, by = 1, nope = 2);  x + by;  end
  end

  def snarf(options) #:nodoc:
    return options[:zone]
  end

  def test_reflect_constants
    y =   6
    assert{ /LinkHogThrob == "L\#\{ 1 \+ y \}".*LinkHogThrob.*L7/m =~
               reflect{ LinkHogThrob == "L#{ 1 + y }" } }
  end

  def test_reflect_functions_with_arguments_splats_hashes_and_blockers
    foo      = Foo.new
    y        = 2
    splat_me = [40, 2]
    block_me = proc{ y + 1 }

# pp "def foo(*)\nend\n".parse_to_nodes.transform

    assert_match /foo.*\.inc\(41\) == 42/, reflect{ foo.inc(41) == 42 }

    assert{ /foo.*\.inc\(41, y\) == 42/ =~
                 reflect{ foo.inc(41, y) == 42 } }

    assert{ /foo.*\.inc\(\*\[41, y\]\) == 42/ =~
                 reflect{ foo.inc(*[41, y]) == 42 } }

    assert{ /foo.*\.inc\(\*splat_me\)/ =~
                 reflect{ foo.inc(*splat_me) == 42 } }

    assert{ reflect{ foo.inc(2, *splat_me) == 42 }.
               index("foo.inc(2, *splat_me)") }

    assert{ reflect{ foo.inc(2, *splat_me, &block_me) == 42 }.
               index("foo.inc(2, *splat_me, &block_me) == 42\t--> true") }

    assert{ reflect{ snarf :zing => y, :zone => 42 }.
             index('snarf({ :zing => y, :zone => 42 })') }

    assert{ /snarf\(\{ :zing => 41, :zone => 42 \}\)/ =~
                 reflect{ snarf({ :zing => 41, :zone => 42 }) } }
  end

  def test_reflect_arrays
    colorize(false)
    assert{ '4yo2'.index('yo')   }
      deny{ '4yo2'.index('yoyo') }
    q = 2
    zone = [4, q]
    assert_match 'zone == [4, 2]',       reflect{ zone == [4, 2] }
    assert_match /zone\s+--\> \[4, 2\]/, reflect{ zone == [4, 2] }
    assert_match 'zone == [4, q]',       reflect{ zone == [4, q] }
    assert_match /\ \ \ \ q\s+--\> 2/,   reflect{ zone == [4, q] }

    if :to_s.respond_to? :to_proc
      assert_match /zone.map\(&:to_s\) == \[\"4\", q/,
                   reflect{ zone.map(&:to_s) == ['4', q.to_s] }

      assert_{ reflect{ zone.map(&:to_s) == ['4', q.to_s] } =~
                       /zone.map\(&\:to_s\)\s+--> \["4", "2"\]/ }
    end
  end

  def test_reflect_hash
    colorize(false)
    a = { :href => 'Snoopy' }
    reflection = reflect{ /opy$/ =~ a[:href] }
# puts reflection
    assert_{ reflection.index("/opy$/ =~ a[:href]\t--> 3") }
    assert_{ reflection.index("--> {:href=>\"Snoopy\"}") }
  end

  def test_reflect_instance_of
    that = self  #  ERGO  can't we bind to this context correctly?
    assert_match /that.*instance_of?.*Test::Unit::TestCase/, reflect{ that.instance_of?(Test::Unit::TestCase) }
    assert_match /that.*kind_of?.*Test::Unit::TestCase/, reflect{ that.kind_of?(Test::Unit::TestCase) }
  end

  def test_reflect_operator
    f = -4.2
    assert_{ /f >= 0.0/ =~ reflect{ f >= 0.0 } }
  end

  def test_reflect_nil_true_false
    q, @t, @f = nil, true, false
    assert_{ /nil/           =~ reflect{ nil         } }
    assert_{ /nil\.nil\?/    =~ reflect{ nil.nil?    } }
    assert_{ /q.*q.*nil/m    =~ reflect{ q == nil    } }
    assert_{ /true/          =~ reflect{ true        } }
    assert_{ /@t.*@t.*true/m =~ reflect{ @t == true  } }
    assert_{ /false/         =~ reflect{ false       } }
    assert_{ /@f == false/m  =~ reflect{ @f == false } }
  end

  def test_operator_madness
    colorize(false)
    assert_{ reflect{ q = 40 }.index('q = 40') }
    n = 12
    m =  2
    madness = reflect{ (n == 12 and m == 2) ? n * 2 : 23 }

    assert_ do
      madness.index('( if ( ( ( n == 12 ) and ( m == 2 ) ) ) then ( n * 2 ) else ( 23 ) end )')
    end

    assert_{ madness.match(/n\s+--> 12/) }
    assert_{ madness.match(/\( n == 12 \)\s+--> true/) }
    assert_{ madness =~ /n\s+--> 12/ }
    assert_{ madness.match( /\( n \* 2 \)\s+--> 24/ ) }
    assert_{ madness =~ /\( 23 \)\s+--> 23/ }
    madness = reflect{ (n == 12 && m == 2) ? n * 2 : 23 }
    assert_{ madness.index('( n == 12 ) and ( m == 2 )') }
    madness = reflect{ n || m }
    assert_{ madness.index('( n ) or ( m )') }

    assert_ do
      reflect{ if n == 12 then n * 2 else 23 end }.
               index('( if ( n == 12 ) then ( n * 2 ) else ( 23 ) end )')
    end

    assert_ do
      reflect{ if n == 12 then n * 2 end }.
               index('( if ( n == 12 ) then ( n * 2 ) end )')
    end
  end

  def test_reflect_linefeeds_and_parens
    reflection = reflect do
                   q = 42
                   q == (21 + 21) * 1
                 end
    assert_{ reflection.index("q = 42\nq == ( ( 21 + 21 ) * 1 )\n\t--> true") }
  end

  def test_we_dont_do_plus_equals_like_that
    assert{ 'foo = foo + 1' == reflect_string('foo += 1') }
  end

  def test_reflect_map_index
    colorize(false)
    mapper = { 'foo' => 'cue'}
    reflection = reflect{ 'cue' == mapper['foo'] }
    assert{ reflection.index("\"cue\" == ( mapper[\"foo\"] )") }
    assert{ reflection.index("( mapper[\"foo\"] )") }
    assert{ reflection.index("--> \"cue\"") }
  end

  def test_reflect_inverse_parens
    reflection = reflect{ q = 21 + (21 * 1) }
    assert{ reflection.index("q = 21 + ( 21 * 1 )") }
  end

  def test_reflect_functions
    x = 42
    y = 43
    foo = Foo.new
    assert{ /foo.bar\(\) == 42.*foo.bar.*42/m =~ reflect{ foo.bar() == 42 } }
    assert{ /foo.bar\(\) == x/        =~ reflect{ foo.bar() == x } }
    assert{ /foo.bar\(\) == y/        =~ reflect{ foo.bar() == y } }
    assert{ /foo.sym\(\) == :bol.*foo.sym.*:bol/m =~ reflect{ foo.sym() == :bol } }
    assert{ /42 == foo.bar/           =~ reflect{ 42 == foo.bar() } }
    assert{ /x == foo.bar/            =~ reflect{ x == foo.bar() } }
    assert{ /y == foo.bar/            =~ reflect{ y == foo.bar() } }
    assert{ /foo.bar\(\) == foo.bar/  =~ reflect{ foo.bar == foo.bar() } }
    assert{ /\(not\(foo.bar\(\) == y\)\)/ =~ reflect{ foo.bar() != y } }
  end

  def test_backticks
    assert{ reflect_source{ `exon is #{foo}` } == "`exon is \#{ foo }`" }
    assert{ reflect_source{ `hatch is \#` } == "`hatch is #`" }
    assert{ reflect_source{ `intron is \#{nope` } == "`intron is \\\#{nope`" }
    assert{ reflect_source{ `solidus is \\` } == "`solidus is \\\\`" }
    assert{ reflect_source{ `quotes are \'\"` } == "`quotes are '\\\"`" }
    #  ERGO  is this a bug in the parser?
    # assert{ reflect_source{ `ticks are \`` } == "`ticks are \\`" }
  end

  def test_reflect_literal_strings
    colorize(false)
    x = '42'
    y =   1
    assert_equal "x == \"42\"\t--> true\n    x --> \"42\"", reflect{ x == '42' }
    assert_equal "\"42\" == x\t--> true\n    x --> \"42\"", reflect{ '42' == x }
    assert{ /"4\#\{ 1 \+ y \}"/                =~ reflect{ x == "4#{ 1 + y }" } }
    assert{ /"\#\{ 3 \+ y \}2"/                =~ reflect{ x == "#{ 3 + y }2" } }
    assert{ /"\#\{ 3 \}yoyo\#\{ 1 \}"/         =~ reflect{ x == "#{ 3 }yoyo#{ 1 }" } }
    assert{ /"\#\{ 3 \+ y \}yo\#\{ 1 \+ y \}"/ =~ reflect{ x == "#{ 3 + y }yo#{ 1 + y }" } }
    assert{ /"\#\{ 3 \+ y \}\#\{ 1 \+ y \}"/   =~ reflect{ x == "#{ 3 + y }#{ 1 + y }" } }
  end

  def test_reflect
    x = 42
    y = 43
    assert{ reflect{  x == 42 }.index("x == 42\t--> true"       ) == 0 }
    assert{ reflect{ 42 ==  x }.index("42 == x\t--> true"       ) == 0 }
    assert{ reflect{  y == 41 }.index("y == 41\t--> false"      ) == 0 }
    assert{ reflect{ 41 ==  y }.index("41 == y\t--> false"      ) == 0 }
    assert{ reflect{  y >= 41 }.index("y >= 41\t--> true"       ) == 0 }
    assert{ reflect{ 41 <=  y }.index("41 <= y\t--> true"       ) == 0 }
    assert{ reflect{  y >  41 }.index("y > 41\t--> true"        ) == 0 }
    assert{ reflect{ 41 <   y }.index("41 < y\t--> true"        ) == 0 }
    assert{ reflect{  y != 41 }.index("(not(y == 41))\t--> true") == 0 }
    assert{ reflect{ 41 !=  y }.index("(not(41 == y))\t--> true") == 0 }
  end

  #############################################################
  ######## whatnot

  def test_each_slice
    twizzled = []
    [1, 2, 3, 7].in_groups_of(2){|a,z| twizzled << [a,z]}
    assert{ twizzled == [[1, 2], [3, 7]] }
  end

  class BufferStdout #:nodoc:
    def tty?; false end
    def write(stuff)
      (@output ||= '') << stuff
    end
    def <<(stuff)
      (@output ||= '') << stuff
    end
    def output;  @output || ''  end
  end

  def assert_stdout(matcher = nil, diagnostic = nil)  #:nodoc:
    waz, $stdout = $stdout, BufferStdout.new
    yield
    assert_match matcher, $stdout.output, diagnostic  if matcher
    return $stdout.output
  ensure
    $stdout = waz
  end

  def assert_stderr(matcher = nil, diagnostic = nil)  #:nodoc:
    waz, $stderr = $stderr, BufferStdout.new
    yield
    assert_match matcher, $stderr.output, diagnostic  if matcher
    return $stderr.output
  ensure
    $stderr = waz
  end

end
