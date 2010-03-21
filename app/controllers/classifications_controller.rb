class ClassificationsController < ApplicationController

  def liked
    entry = Entry.find(params[:id])
    @current_user.liked!(entry)
    @current_user.read!(entry)

    respond_to do |format|
      format.js { render :json => true }
    end
  end

  def disliked
    entry = Entry.find(params[:id])    
    @current_user.disliked!(entry)
    @current_user.read!(entry)
    
    respond_to do |format|
      format.js { render :json => true }
    end
  end

  #scaffolded, will prolly use later. Not routed to atm.

  # GET /classifications
  # GET /classifications.xml
  def index
    @classifications = Classification.paginate_by_sql(["select * from classifications where user_id = ? order by id DESC", @current_user.id], { :per_page => 3, :page => params[:page] })


    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @classifications }
    end
  end

  def more
    @classifications = Classification.paginate_by_sql(["select * from classifications where user_id = ? order by id DESC", @current_user.id], { :per_page => 10, :page => params[:page] })

    render :index, :layout => false
  end

  # GET /classifications/1
  # GET /classifications/1.xml
  def show
    @classification = Classification.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @classification }
    end
  end

  # GET /classifications/new
  # GET /classifications/new.xml
  def new
    @classification = Classification.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @classification }
    end
  end

  # GET /classifications/1/edit
  def edit
    @classification = Classification.find(params[:id])
  end

  # POST /classifications
  # POST /classifications.xml
  def create
    @classification = Classification.new(params[:classification])

    respond_to do |format|
      if @classification.save
        flash[:notice] = 'Classification was successfully created.'
        format.html { redirect_to(@classification) }
        format.xml  { render :xml => @classification, :status => :created, :location => @classification }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @classification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /classifications/1
  # PUT /classifications/1.xml
  def update
    @classification = Classification.find(params[:id])

    respond_to do |format|
      if @classification.update_attributes(params[:classification])
        flash[:notice] = 'Classification was successfully updated.'
        format.html { redirect_to(@classification) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @classification.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /classifications/1
  # DELETE /classifications/1.xml
  def destroy
    @classification = Classification.find(params[:id])
    @classification.destroy

    respond_to do |format|
      format.html { redirect_to(classifications_url) }
      format.xml  { head :ok }
    end
  end
end
