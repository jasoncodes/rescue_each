# `rescue_each`
## Rescue multiple exceptions when enumerating over Enumerable or ActiveRecord objects.

Say you have a batch rake task which runs from cron which consists of many independent tasks ran in a loop.
These tasks could be anything from updating cached database entries to file conversions.

Once of these tasks fails, perhaps there's a corrupt image. Normally this would mean the entire batch task fails. But with rescue_each the other items can be processed and any errors will be re-raised at the end to be caught by your cron script.

### Installation

You can install from Gemcutter by running:

    sudo gem install rescue_each

### Usage

#### Basics

Simply replace your `each` calls with `rescue_each`:

    BatchTasks.all.each &:process!

transforms into:

    BatchTasks.all.rescue_each &:process!

#### Verbosity

`rescue_each` also supports a option to output error summary info to `stderr` during the loop:

    (1..5).rescue_each :stderr => true do |i|
      sleep 1
      raise 'example'
    end

You'll probably find this handy if your batch task has its own status output as this mode will output an error summary inline.

#### Other Methods

`rescue_each` also provides proxies for `map`, `each_with_index`, `find_each` and `find_in_batches`.
You can also use `rescue_each` on any method taking a block by calling `rescue_send`:

    odds = (1..5).rescue_send(:reject) { |i| i%2 == 0 }

### Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2010 Jason Weathered. See LICENSE for details.
