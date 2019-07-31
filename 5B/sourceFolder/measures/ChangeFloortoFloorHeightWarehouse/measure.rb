# start the measure
class ChangeFloortoFloorHeightWarehouse < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "changeFloortoFloorHeightWarehouse"
  end

  # human readable description
  def description
    return "Changes the floor to floor height of the storage space in a warehouse."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Does not change the height of the office space."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for floor height
    floor_to_floor_height_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_to_floor_height_ip",true)
    floor_to_floor_height_ip.setDisplayName("Floor to Floor Height Increase (ft).")
    floor_to_floor_height_ip.setDefaultValue(1.0)
    args << floor_to_floor_height_ip

    return args
  end #end the arguments method	
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    floor_to_floor_height_ip = runner.getDoubleArgumentValue("floor_to_floor_height_ip",user_arguments)

    #test for positive inputs
    if floor_to_floor_height_ip > 100 or floor_to_floor_height_ip < -100
      runner.registerError("Value is too large.")
    end	

    #helper to make it easier to do unit conversions on the fly.  The definition be called through this measure.
    def unit_helper(number,from_unit_string,to_unit_string)
      converted_number = OpenStudio::convert(OpenStudio::Quantity.new(number, OpenStudio::createUnit(from_unit_string).get), OpenStudio::createUnit(to_unit_string).get).get.value
    end
	
	#transfer unit from ip to si
    floor_to_floor_height = unit_helper(floor_to_floor_height_ip,"ft","m")
	
	#reporting initial condition of model
    external_wall_surfaces = model.getSurfaces
	runner.registerInitialCondition("The building started with #{external_wall_surfaces.size}.")
	
	zmin = 100_000_000_000
	zmax = 0
	z_sec_max = 0
	
	# loop over all external walls
	external_wall_surfaces.each do |external_wall_surface|
	  if external_wall_surface.surfaceType == "Wall"
	
        # get the existing vertices for this interior partition
        vertices = external_wall_surface.vertices
	  
	    # The highest and lowest values of z
        vertices.each do |vertex|

          # initialize new vertex to old vertex
          x = vertex.x
          y = vertex.y
          z = vertex.z
		
		  # get the highest and lowest values of z		  
		  if z > zmax
		    zmax = z
		  end
		
		  if z < zmin
		    zmin = z
		  end
	    end
	  end
	end
	
	# ger the second highest value of z
	external_wall_surfaces.each do |external_wall_surface|
	  if external_wall_surface.surfaceType == "Wall"
	
        # get the existing vertices for this interior partition
        vertices = external_wall_surface.vertices
	  
	    # The highest and lowest values of z
        vertices.each do |vertex|

          # initialize new vertex to old vertex
          x = vertex.x
          y = vertex.y
          z = vertex.z
		
		  # get the highest and lowest values of z		  
		  if z < zmax and z > z_sec_max
		    z_sec_max = z
		  end
	    end
	  end
	end
	
	if z_sec_max - zmax > floor_to_floor_height
		runner.registerError("Value is too large.")
	end
	
    # loop over all external walls
    external_wall_surfaces.each do |external_wall_surface|
	
	  # create a new set of vertices
      newVertices = OpenStudio::Point3dVector.new
	  
	  if external_wall_surface.surfaceType == "Wall" or external_wall_surface.surfaceType == "RoofCeiling"

        # get the existing vertices for this exterior partition
        vertices = external_wall_surface.vertices
	  
        vertices.each do |vertex|

          # initialize new vertex to old vertex
          x = vertex.x
          y = vertex.y
          z = vertex.z
		
		  if z == zmax
		    z = z + floor_to_floor_height
		  end
		
          # add point to new vertices
          newVertices << OpenStudio::Point3d.new(x,y,z)
        end
      end
	  
      # set vertices to new vertices
      external_wall_surface.setVertices(newVertices)
    end
	
	# internal walls
	internal_wall_surfaces = model.getInteriorPartitionSurfaces
    # loop over all internal walls
    internal_wall_surfaces.each do |internal_wall_surface|
	
	  # create a new set of vertices
      newVertices = OpenStudio::Point3dVector.new

  	  # get the existing vertices for this internal partition
	  vertices = internal_wall_surface.vertices
  
	  vertices.each do |vertex|

	    # initialize new vertex to old vertex
	    x = vertex.x
	    y = vertex.y
	    z = vertex.z
	
	    if z == zmax
		  z = z + floor_to_floor_height
	    end
		
	    # add point to new vertices
	    newVertices << OpenStudio::Point3d.new(x,y,z)
	  end
	  
      # set vertices to new vertices
      internal_wall_surface.setVertices(newVertices)
    end
	
	# skylights
	skylight_surfaces = model.getSubSurfaces
    # loop over all skylights
    skylight_surfaces.each do |skylight_surface|
	
	  # create a new set of vertices
      newVertices = OpenStudio::Point3dVector.new

  	  # get the existing vertices for this skylights
	  vertices = skylight_surface.vertices
  
	  vertices.each do |vertex|

	    # initialize new vertex to old vertex
	    x = vertex.x
	    y = vertex.y
	    z = vertex.z
	
	    if (z - zmax).abs < 0.0001
		  z = z + floor_to_floor_height
	    end
		
	    # add point to new vertices
	    newVertices << OpenStudio::Point3d.new(x,y,z)
	  end
	  
      # set vertices to new vertices
      skylight_surface.setVertices(newVertices)
    end
	
    #reporting final condition of model
    finishing_spaces = model.getSurfaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size}.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ChangeFloortoFloorHeightWarehouse.new.registerWithApplication
