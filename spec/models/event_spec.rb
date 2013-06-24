require 'spec_helper'

describe Event do

  before :all do
    Event.delete_all
    Event.create(data_type: "loan", time_stamp: "2013-01-02", primary_attribute: "applied", secondary_attribute: "paid_in_full")
    Event.create(data_type: "call", time_stamp: "2013-01-04", primary_attribute: "approved", secondary_attribute: "defaulted")
  end

  it "gets events between given dates" do
    events_between_dates = Event.date_between("2013-01-01", "2013-01-03")

    events_between_dates.should have(1).event
    events_between_dates.first.time_stamp.should == "2013-01-02 00:00:00"

  end

  it "gets events of given type" do
    Event.type('loan').should have(1).event
    Event.type('call').should have(1).event
  end

  it "gets events of given primary_attribute" do
    Event.primary_attribute("applied").should have(1).event
    Event.primary_attribute("applied").first.primary_attribute.should == "applied"


    Event.primary_attribute("approved").should have(1).event
    Event.primary_attribute("approved").first.primary_attribute.should == "approved"
    end

  it "gets events of given secondary_attribute" do
    Event.secondary_attribute("paid_in_full").should have(1).event
    Event.secondary_attribute("defaulted").should have(1).event
  end

  it "gets type, primary and secondary attribute filters based on data in the database" do
    expect(Event.get_filters[:type]).to include("loan","call")
    expect(Event.get_filters[:primary_attribute]).to include("applied", "approved")
    expect(Event.get_filters[:secondary_attribute]).to include("paid_in_full", "defaulted")
  end

  it "merges defaults into options with keys already present in options taking precedence" do
    options = {}
    options.should_receive(:reverse_merge!)
    Event.get_events_for options
  end

  it "fills in default params for missing params on #get_events_for" do
    options = {}
    Event.get_events_for options
    expect(options).to include(start: "2013-03-01", finish: "2013-06-01",
                               scope: "state", pie_limit: 10,
                               bar_limit: 5,
                               type: "all",
                               primary_attribute: "all",
                               secondary_attribute: "all",
                               lower_bound: 0,
                               upper_bound: 50000)
  end

end
