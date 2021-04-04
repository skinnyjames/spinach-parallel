module DoubleDecker
  class Queue
    
    attr_reader :run_id
    
    def initialize(run_id, store, *items)
      @run_id = run_id
      @store = store
      setup!(items)
    end

    def shift
      queue = JSON.parse(get)
      item = queue.shift
      commit(queue)
      item
    end

    def active?
      !!get
    end

    def empty?
      JSON.parse(get).empty?
    end

    def teardown!
      @store.del("#{run_id}_queue") if get
    end

    private

    def commit(queue)
      @store.set("#{run_id}_queue", queue.to_json)
    end

    def get
      @store.get("#{run_id}_queue")
    end

    def setup!(items)
      get || @store.set("#{run_id}_queue", items.to_json)
    end

  end

  class Bus
    def register_queue(*items)
      Queue.new(@run_id, @store, *items)
    end
  end
end