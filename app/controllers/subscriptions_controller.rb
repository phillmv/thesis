class SubscriptionsController < ApplicationController
  # GET /subscriptions
  # GET /subscriptions.xml
  def index
    @subscriptions = @current_user.subscriptions

    render :index
  end

  # GET /subscriptions/1
  # GET /subscriptions/1.xml
  def show
    @subscription = Subscription.find(params[:id])
    @subscription_entries =  Entry.paginate_by_sql(["select * from entries e where exists (select id from subscriptions_users su where su.user_id = ? and e.subscription_id = ?) order by published ASC", @current_user.id, params[:id]], :per_page => 10, :page => params[:page])

    render :show

  end

  def more
    show()
  end

  # GET /subscriptions/new
  # GET /subscriptions/new.xml
  def new
    @subscription = Subscription.new

    respond_to do |format|
      format.html # new.html.haml
      format.xml  { render :xml => @subscription }
    end
  end

  # GET /subscriptions/1/edit
  def edit
    @subscription = Subscription.find(params[:id])
  end

  # POST /subscriptions
  # POST /subscriptions.xml
  def create
    @subscription = Subscription.find_or_create_by_feed_url(params[:subscription][:feed_url])
   
    @current_user.subscribe(@subscription)

    Metadata.populate!
    Stream.populate_user(@current_user)
    
    respond_to do |format|
      if @subscription.valid?
    
        flash[:notice] = 'Your subscription was successfully added!'
        format.html { redirect_to(:action => "index", :controller => "magazine") }
        format.xml  { render :xml => @subscription, :status => :created, :location => @subscription }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  def remove
    if @current_user.subscriptions.delete(Subscription.find(params[:id]))
      flash[:notice] = "Subscription was removed."
      redirect_to :back
    end
  end

  # PUT /subscriptions/1
  # PUT /subscriptions/1.xml
  def update
    @subscription = Subscription.find(params[:id])

    respond_to do |format|
      if @subscription.update_attributes(params[:subscription])
        flash[:notice] = 'Subscription was successfully updated.'
        format.html { redirect_to(@subscription) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriptions/1
  # DELETE /subscriptions/1.xml
  def destroy
    @subscription = Subscription.find(params[:id])
    @subscription.destroy

    respond_to do |format|
      format.html { redirect_to(subscriptions_url) }
      format.xml  { head :ok }
    end
  end
end
