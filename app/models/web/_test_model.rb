module Web
  class TestModel
    require_relative '../../../../si/db/models'
    require_relative '../../../../si/lib/utils'
    #require_relative '../../../../si/lib/amqp'

    def initialize
      puts 'initialize ok'
      puts '++'
      user = DB::USer.last
      puts user.inspect
      puts '++'
    end
  end
end