-- https://v3rm.net/threads/release-lua-drawing-library.27065/
local cloneref = cloneref or function(...) return ... end
local core_gui_provider = gethui and gethui() or cloneref(game:GetService("CoreGui"))
local camera_matrix_transformer = workspace.CurrentCamera
local drawing_surface_container = Instance.new("ScreenGui")
drawing_surface_container.Name = "Drawing"
drawing_surface_container.IgnoreGuiInset = true
drawing_surface_container.DisplayOrder = 2147483647
drawing_surface_container.Parent = core_gui_provider

local instance_allocation_counter = 0
local registered_visual_elements = table.create(0)

local base_visual_prototype = setmetatable({
    visibility_state = true,
    layer_priority = 0,
    opacity_inverse = 1,
    color_value = Color3.new(),
    removal_operation = function(self)
        setmetatable(self, nil)
    end,
    destruction_operation = function(self)
        setmetatable(self, nil)
    end
}, {
    __add = function(prototype_instance_a, prototype_instance_b)
        local merged_properties = table.clone(prototype_instance_a)

        for property_index, property_value in prototype_instance_b do
            merged_properties[property_index] = property_value
        end
        return merged_properties
    end
})

local font_mapping_table = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono),
}

local function font_resolver_from_index(font_index)
    return font_mapping_table[font_index]
end

local function opacity_inverse_transformer(opacity_value)
    return math.clamp(1 - opacity_value, 0, 1)
end

local drawing_interface = {}
drawing_interface.Fonts = {
    modern_interface = 0,
    system_default = 1,
    clean_sans = 2,
    monospace_code = 3
}

function drawing_interface.new(primitive_type_classification)
    instance_allocation_counter = instance_allocation_counter + 1
    
    if primitive_type_classification == "Line" then
        local line_primitive_properties = ({
            origin_coordinate = Vector2.zero,
            terminal_coordinate = Vector2.zero,
            stroke_weight = 1
        } + base_visual_prototype)

        local line_rendering_container = Instance.new("Frame")
        line_rendering_container.Name = instance_allocation_counter
        line_rendering_container.AnchorPoint = Vector2.new(0.5, 0.5)
        line_rendering_container.BorderSizePixel = 0

        line_rendering_container.BackgroundColor3 = line_primitive_properties.color_value
        line_rendering_container.Visible = line_primitive_properties.visibility_state
        line_rendering_container.ZIndex = line_primitive_properties.layer_priority
        line_rendering_container.BackgroundTransparency = opacity_inverse_transformer(line_primitive_properties.opacity_inverse)

        line_rendering_container.Size = UDim2.new()

        line_rendering_container.Parent = drawing_surface_container
        
        return setmetatable(table.create(0), {
            __newindex = function(_, property_identifier, new_value)
                if typeof(line_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "origin_coordinate" then
                    local direction_vector = (line_primitive_properties.terminal_coordinate - new_value)
                    local center_point = (line_primitive_properties.terminal_coordinate + new_value) / 2
                    linear_distance = direction_vector.Magnitude
                    local rotation_angle = math.deg(math.atan2(direction_vector.Y, direction_vector.X))

                    line_rendering_container.Position = UDim2.fromOffset(center_point.X, center_point.Y)
                    line_rendering_container.Rotation = rotation_angle
                    line_rendering_container.Size = UDim2.fromOffset(linear_distance, line_primitive_properties.stroke_weight)
                    
                elseif property_identifier == "terminal_coordinate" then
                    local direction_vector = (new_value - line_primitive_properties.origin_coordinate)
                    local center_point = (new_value + line_primitive_properties.origin_coordinate) / 2
                    linear_distance = direction_vector.Magnitude
                    local rotation_angle = math.deg(math.atan2(direction_vector.Y, direction_vector.X))

                    line_rendering_container.Position = UDim2.fromOffset(center_point.X, center_point.Y)
                    line_rendering_container.Rotation = rotation_angle
                    line_rendering_container.Size = UDim2.fromOffset(linear_distance, line_primitive_properties.stroke_weight)
                    
                elseif property_identifier == "stroke_weight" then
                    local current_linear_distance = (line_primitive_properties.terminal_coordinate - line_primitive_properties.origin_coordinate).Magnitude
                    line_rendering_container.Size = UDim2.fromOffset(current_linear_distance, new_value)
                    
                elseif property_identifier == "visibility_state" then
                    line_rendering_container.Visible = new_value
                    
                elseif property_identifier == "layer_priority" then
                    line_rendering_container.ZIndex = new_value
                    
                elseif property_identifier == "opacity_inverse" then
                    line_rendering_container.BackgroundTransparency = opacity_inverse_transformer(new_value)
                    
                elseif property_identifier == "color_value" then
                    line_rendering_container.BackgroundColor3 = new_value
                end
                
                line_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        line_rendering_container:Destroy()
                        line_primitive_properties.removal_operation(self)
                        return line_primitive_properties.removal_operation()
                    end
                end
                return line_primitive_properties[property_identifier]
            end,
            
            __tostring = function() 
                return "Drawing" 
            end
        })
        
    elseif primitive_type_classification == "Text" then
        local text_primitive_properties = ({
            textual_content = "",
            typeface_identifier = drawing_interface.Fonts.modern_interface,
            font_dimensions = 0,
            spatial_coordinate = Vector2.zero,
            centered_alignment = false,
            outline_effect = false,
            outline_color_value = Color3.new()
        } + base_visual_prototype)

        local text_display_element = Instance.new("TextLabel")
        local outline_stroke_element = Instance.new("UIStroke")
        
        text_display_element.Name = instance_allocation_counter
        text_display_element.AnchorPoint = Vector2.new(0.5, 0.5)
        text_display_element.BorderSizePixel = 0
        text_display_element.BackgroundTransparency = 1

        text_display_element.Visible = text_primitive_properties.visibility_state
        text_display_element.TextColor3 = text_primitive_properties.color_value
        text_display_element.TextTransparency = opacity_inverse_transformer(text_primitive_properties.opacity_inverse)
        text_display_element.ZIndex = text_primitive_properties.layer_priority

        text_display_element.FontFace = font_resolver_from_index(text_primitive_properties.typeface_identifier)
        text_display_element.TextSize = text_primitive_properties.font_dimensions

        text_display_element:GetPropertyChangedSignal("TextBounds"):Connect(function()
            local text_boundary_dimensions = text_display_element.TextBounds
            local half_dimension_offset = text_boundary_dimensions / 2

            text_display_element.Size = UDim2.fromOffset(text_boundary_dimensions.X, text_boundary_dimensions.Y)
            
            local x_position_component = text_primitive_properties.spatial_coordinate.X
            if not text_primitive_properties.centered_alignment then
                x_position_component = x_position_component + half_dimension_offset.X
            end
            
            text_display_element.Position = UDim2.fromOffset(
                x_position_component, 
                text_primitive_properties.spatial_coordinate.Y + half_dimension_offset.Y
            )
        end)

        outline_stroke_element.Thickness = 1
        outline_stroke_element.Enabled = text_primitive_properties.outline_effect
        outline_stroke_element.Color = text_primitive_properties.color_value

        text_display_element.Parent = drawing_surface_container
        outline_stroke_element.Parent = text_display_element
        
        return setmetatable(table.create(0), {
            __newindex = function(_, property_identifier, new_value)
                if typeof(text_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "textual_content" then
                    text_display_element.Text = new_value
                    
                elseif property_identifier == "typeface_identifier" then
                    new_value = math.clamp(new_value, 0, 3)
                    text_display_element.FontFace = font_resolver_from_index(new_value)
                    
                elseif property_identifier == "font_dimensions" then
                    text_display_element.TextSize = new_value
                    
                elseif property_identifier == "spatial_coordinate" then
                    local half_dimension_offset = text_display_element.TextBounds / 2
                    
                    local x_position_component = new_value.X
                    if not text_primitive_properties.centered_alignment then
                        x_position_component = x_position_component + half_dimension_offset.X
                    end
                    
                    text_display_element.Position = UDim2.fromOffset(
                        x_position_component, 
                        new_value.Y + half_dimension_offset.Y
                    )
                    
                elseif property_identifier == "centered_alignment" then
                    local target_position
                    
                    if new_value then
                        target_position = camera_matrix_transformer.ViewportSize / 2
                    else
                        target_position = text_primitive_properties.spatial_coordinate
                    end
                    
                    text_display_element.Position = UDim2.fromOffset(target_position.X, target_position.Y)
                    
                elseif property_identifier == "outline_effect" then
                    outline_stroke_element.Enabled = new_value
                    
                elseif property_identifier == "outline_color_value" then
                    outline_stroke_element.Color = new_value
                    
                elseif property_identifier == "visibility_state" then
                    text_display_element.Visible = new_value
                    
                elseif property_identifier == "layer_priority" then
                    text_display_element.ZIndex = new_value
                    
                elseif property_identifier == "opacity_inverse" then
                    local transformed_opacity = opacity_inverse_transformer(new_value)
                    text_display_element.TextTransparency = transformed_opacity
                    outline_stroke_element.Transparency = transformed_opacity
                    
                elseif property_identifier == "color_value" then
                    text_display_element.TextColor3 = new_value
                end
                
                text_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        text_display_element:Destroy()
                        text_primitive_properties.removal_operation(self)
                        return text_primitive_properties.removal_operation()
                    end
                    
                elseif property_identifier == "TextBounds" then
                    return text_display_element.TextBounds
                end
                
                return text_primitive_properties[property_identifier]
            end,
            
            __tostring = function() 
                return "Drawing" 
            end
        })
        
    elseif primitive_type_classification == "Circle" then
        local circular_primitive_properties = ({
            radial_dimension = 150,
            spatial_coordinate = Vector2.zero,
            boundary_thickness = 0.7,
            filled_interior = false
        } + base_visual_prototype)

        local circular_container = Instance.new("Frame")
        local corner_rounding_effect = Instance.new("UICorner")
        local boundary_stroke_element = Instance.new("UIStroke")
        
        circular_container.Name = instance_allocation_counter
        circular_container.AnchorPoint = Vector2.new(0.5, 0.5)
        circular_container.BorderSizePixel = 0

        if circular_primitive_properties.filled_interior then
            circular_container.BackgroundTransparency = opacity_inverse_transformer(circular_primitive_properties.opacity_inverse)
        else
            circular_container.BackgroundTransparency = 1
        end
        
        circular_container.BackgroundColor3 = circular_primitive_properties.color_value
        circular_container.Visible = circular_primitive_properties.visibility_state
        circular_container.ZIndex = circular_primitive_properties.layer_priority

        corner_rounding_effect.CornerRadius = UDim.new(1, 0)
        circular_container.Size = UDim2.fromOffset(
            circular_primitive_properties.radial_dimension, 
            circular_primitive_properties.radial_dimension
        )

        boundary_stroke_element.Thickness = circular_primitive_properties.boundary_thickness
        boundary_stroke_element.Enabled = not circular_primitive_properties.filled_interior
        boundary_stroke_element.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        circular_container.Parent = drawing_surface_container
        corner_rounding_effect.Parent = circular_container
        boundary_stroke_element.Parent = circular_container
        
        return setmetatable(table.create(0), {
            __newindex = function(_, property_identifier, new_value)
                if typeof(circular_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "radial_dimension" then
                    local diameter_value = new_value * 2
                    circular_container.Size = UDim2.fromOffset(diameter_value, diameter_value)
                    
                elseif property_identifier == "spatial_coordinate" then
                    circular_container.Position = UDim2.fromOffset(new_value.X, new_value.Y)
                    
                elseif property_identifier == "boundary_thickness" then
                    new_value = math.clamp(new_value, 0.6, 2147483647)
                    boundary_stroke_element.Thickness = new_value
                    
                elseif property_identifier == "filled_interior" then
                    if new_value then
                        circular_container.BackgroundTransparency = opacity_inverse_transformer(circular_primitive_properties.opacity_inverse)
                    else
                        circular_container.BackgroundTransparency = 1
                    end
                    boundary_stroke_element.Enabled = not new_value
                    
                elseif property_identifier == "visibility_state" then
                    circular_container.Visible = new_value
                    
                elseif property_identifier == "layer_priority" then
                    circular_container.ZIndex = new_value
                    
                elseif property_identifier == "opacity_inverse" then
                    local transformed_opacity = opacity_inverse_transformer(new_value)
                    
                    if circular_primitive_properties.filled_interior then
                        circular_container.BackgroundTransparency = transformed_opacity
                    else
                        circular_container.BackgroundTransparency = 1
                    end
                    
                    boundary_stroke_element.Transparency = transformed_opacity
                    
                elseif property_identifier == "color_value" then
                    circular_container.BackgroundColor3 = new_value
                    boundary_stroke_element.Color = new_value
                end
                
                circular_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        circular_container:Destroy()
                        circular_primitive_properties.removal_operation(self)
                        return circular_primitive_properties.removal_operation()
                    end
                end
                
                return circular_primitive_properties[property_identifier]
            end,
            
            __tostring = function() 
                return "Drawing" 
            end
        })
        
    elseif primitive_type_classification == "Square" then
        local rectangular_primitive_properties = ({
            dimensional_scale = Vector2.zero,
            spatial_coordinate = Vector2.zero,
            boundary_thickness = 0.7,
            filled_interior = false
        } + base_visual_prototype)

        local rectangular_container = Instance.new("Frame")
        local boundary_stroke_element = Instance.new("UIStroke")
        
        rectangular_container.Name = instance_allocation_counter
        rectangular_container.BorderSizePixel = 0

        if rectangular_primitive_properties.filled_interior then
            rectangular_container.BackgroundTransparency = opacity_inverse_transformer(rectangular_primitive_properties.opacity_inverse)
        else
            rectangular_container.BackgroundTransparency = 1
        end
        
        rectangular_container.ZIndex = rectangular_primitive_properties.layer_priority
        rectangular_container.BackgroundColor3 = rectangular_primitive_properties.color_value
        rectangular_container.Visible = rectangular_primitive_properties.visibility_state

        boundary_stroke_element.Thickness = rectangular_primitive_properties.boundary_thickness
        boundary_stroke_element.Enabled = not rectangular_primitive_properties.filled_interior
        boundary_stroke_element.LineJoinMode = Enum.LineJoinMode.Miter

        rectangular_container.Parent = drawing_surface_container
        boundary_stroke_element.Parent = rectangular_container
        
        return setmetatable(table.create(0), {
            __newindex = function(_, property_identifier, new_value)
                if typeof(rectangular_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "dimensional_scale" then
                    rectangular_container.Size = UDim2.fromOffset(new_value.X, new_value.Y)
                    
                elseif property_identifier == "spatial_coordinate" then
                    rectangular_container.Position = UDim2.fromOffset(new_value.X, new_value.Y)
                    
                elseif property_identifier == "boundary_thickness" then
                    new_value = math.clamp(new_value, 0.6, 2147483647)
                    boundary_stroke_element.Thickness = new_value
                    
                elseif property_identifier == "filled_interior" then
                    if new_value then
                        rectangular_container.BackgroundTransparency = opacity_inverse_transformer(rectangular_primitive_properties.opacity_inverse)
                    else
                        rectangular_container.BackgroundTransparency = 1
                    end
                    boundary_stroke_element.Enabled = not new_value
                    
                elseif property_identifier == "visibility_state" then
                    rectangular_container.Visible = new_value
                    
                elseif property_identifier == "layer_priority" then
                    rectangular_container.ZIndex = new_value
                    
                elseif property_identifier == "opacity_inverse" then
                    local transformed_opacity = opacity_inverse_transformer(new_value)
                    
                    if rectangular_primitive_properties.filled_interior then
                        rectangular_container.BackgroundTransparency = transformed_opacity
                    else
                        rectangular_container.BackgroundTransparency = 1
                    end
                    
                    boundary_stroke_element.Transparency = transformed_opacity
                    
                elseif property_identifier == "color_value" then
                    boundary_stroke_element.Color = new_value
                    rectangular_container.BackgroundColor3 = new_value
                end
                
                rectangular_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        rectangular_container:Destroy()
                        rectangular_primitive_properties.removal_operation(self)
                        return rectangular_primitive_properties.removal_operation()
                    end
                end
                
                return rectangular_primitive_properties[property_identifier]
            end,
            
            __tostring = function() 
                return "Drawing" 
            end
        })
        
    elseif primitive_type_classification == "Image" then
        local image_primitive_properties = ({
            binary_representation = "",
            asset_identifier_url = "rbxassetid://0",
            dimensional_scale = Vector2.zero,
            spatial_coordinate = Vector2.zero
        } + base_visual_prototype)

        local image_display_element = Instance.new("ImageLabel")
        
        image_display_element.Name = instance_allocation_counter
        image_display_element.BorderSizePixel = 0
        image_display_element.ScaleType = Enum.ScaleType.Stretch
        image_display_element.BackgroundTransparency = 1

        image_display_element.Visible = image_primitive_properties.visibility_state
        image_display_element.ZIndex = image_primitive_properties.layer_priority
        image_display_element.ImageTransparency = opacity_inverse_transformer(image_primitive_properties.opacity_inverse)
        image_display_element.ImageColor3 = image_primitive_properties.color_value

        image_display_element.Parent = drawing_surface_container
        
        return setmetatable(table.create(0), {
            __newindex = function(_, property_identifier, new_value)
                if typeof(image_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "binary_representation" then
                    -- pending implementation
                    
                elseif property_identifier == "asset_identifier_url" then
                    image_display_element.Image = new_value
                    
                elseif property_identifier == "dimensional_scale" then
                    image_display_element.Size = UDim2.fromOffset(new_value.X, new_value.Y)
                    
                elseif property_identifier == "spatial_coordinate" then
                    image_display_element.Position = UDim2.fromOffset(new_value.X, new_value.Y)
                    
                elseif property_identifier == "visibility_state" then
                    image_display_element.Visible = new_value
                    
                elseif property_identifier == "layer_priority" then
                    image_display_element.ZIndex = new_value
                    
                elseif property_identifier == "opacity_inverse" then
                    image_display_element.ImageTransparency = opacity_inverse_transformer(new_value)
                    
                elseif property_identifier == "color_value" then
                    image_display_element.ImageColor3 = new_value
                end
                
                image_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        image_display_element:Destroy()
                        image_primitive_properties.removal_operation(self)
                        return image_primitive_properties.removal_operation()
                    end
                    
                elseif property_identifier == "binary_representation" then
                    return nil
                end
                
                return image_primitive_properties[property_identifier]
            end,
            
            __tostring = function() 
                return "Drawing" 
            end
        })
        
    elseif primitive_type_classification == "Quad" then
        local quadrilateral_primitive_properties = ({
            edge_thickness_parameter = 1,
            vertex_coordinate_a = Vector2.new(),
            vertex_coordinate_b = Vector2.new(),
            vertex_coordinate_c = Vector2.new(),
            vertex_coordinate_d = Vector2.new(),
            interior_fill_state = false
        } + base_visual_prototype)

        local edge_primitive_a = drawing_interface.new("Line")
        local edge_primitive_b = drawing_interface.new("Line")
        local edge_primitive_c = drawing_interface.new("Line")
        local edge_primitive_d = drawing_interface.new("Line")

        return setmetatable({}, {
            __newindex = function(self, property_identifier, new_value)
                if property_identifier == "edge_thickness_parameter" then
                    edge_primitive_a.stroke_weight = new_value
                    edge_primitive_b.stroke_weight = new_value
                    edge_primitive_c.stroke_weight = new_value
                    edge_primitive_d.stroke_weight = new_value
                end
                
                if property_identifier == "vertex_coordinate_a" then
                    edge_primitive_a.origin_coordinate = new_value
                    edge_primitive_b.terminal_coordinate = new_value
                end
                
                if property_identifier == "vertex_coordinate_b" then
                    edge_primitive_b.origin_coordinate = new_value
                    edge_primitive_c.terminal_coordinate = new_value
                end
                
                if property_identifier == "vertex_coordinate_c" then
                    edge_primitive_c.origin_coordinate = new_value
                    edge_primitive_d.terminal_coordinate = new_value
                end
                
                if property_identifier == "vertex_coordinate_d" then
                    edge_primitive_d.origin_coordinate = new_value
                    edge_primitive_a.terminal_coordinate = new_value
                end
                
                if property_identifier == "visibility_state" then
                    edge_primitive_a.visibility_state = true
                    edge_primitive_b.visibility_state = true
                    edge_primitive_c.visibility_state = true
                    edge_primitive_d.visibility_state = true
                end
                
                if property_identifier == "interior_fill_state" then
                    -- pending implementation
                end
                
                if property_identifier == "color_value" then
                    edge_primitive_a.color_value = new_value
                    edge_primitive_b.color_value = new_value
                    edge_primitive_c.color_value = new_value
                    edge_primitive_d.color_value = new_value
                end
                
                if property_identifier == "layer_priority" then
                    edge_primitive_a.layer_priority = new_value
                    edge_primitive_b.layer_priority = new_value
                    edge_primitive_c.layer_priority = new_value
                    edge_primitive_d.layer_priority = new_value
                end
            end,
            
            __index = function(self, property_identifier)
                if string.lower(tostring(property_identifier)) == "removal_operation" then
                    return function()
                        edge_primitive_a:removal_operation()
                        edge_primitive_b:removal_operation()
                        edge_primitive_c:removal_operation()
                        edge_primitive_d:removal_operation()
                    end
                end
                
                return quadrilateral_primitive_properties[property_identifier]
            end
        })
        
    elseif primitive_type_classification == "Triangle" then
        local triangular_primitive_properties = ({
            vertex_coordinate_a = Vector2.zero,
            vertex_coordinate_b = Vector2.zero,
            vertex_coordinate_c = Vector2.zero,
            edge_thickness_parameter = 1,
            interior_fill_state = false
        } + base_visual_prototype)

        local edge_container_collection = table.create(0)
        edge_container_collection.edge_a = drawing_interface.new("Line")
        edge_container_collection.edge_b = drawing_interface.new("Line")
        edge_container_collection.edge_c = drawing_interface.new("Line")
        
        return setmetatable(table.create(0), {
            __tostring = function() 
                return "Drawing" 
            end,
            
            __newindex = function(_, property_identifier, new_value)
                if typeof(triangular_primitive_properties[property_identifier]) == "nil" then 
                    return 
                end

                if property_identifier == "vertex_coordinate_a" then
                    edge_container_collection.edge_a.origin_coordinate = new_value
                    edge_container_collection.edge_b.terminal_coordinate = new_value
                    
                elseif property_identifier == "vertex_coordinate_b" then
                    edge_container_collection.edge_b.origin_coordinate = new_value
                    edge_container_collection.edge_c.terminal_coordinate = new_value
                    
                elseif property_identifier == "vertex_coordinate_c" then
                    edge_container_collection.edge_c.origin_coordinate = new_value
                    edge_container_collection.edge_a.terminal_coordinate = new_value
                    
                elseif property_identifier == "edge_thickness_parameter" 
                    or property_identifier == "visibility_state" 
                    or property_identifier == "color_value" 
                    or property_identifier == "layer_priority" then
                    
                    for _, edge_primitive_reference in edge_container_collection do
                        edge_primitive_reference[property_identifier] = new_value
                    end
                    
                elseif property_identifier == "interior_fill_state" then
                    -- pending implementation
                end
                
                triangular_primitive_properties[property_identifier] = new_value
            end,
            
            __index = function(self, property_identifier)
                if property_identifier == "removal_operation" or property_identifier == "destruction_operation" then
                    return function()
                        for _, edge_primitive_reference in edge_container_collection do
                            edge_primitive_reference:removal_operation()
                        end
                        
                        triangular_primitive_properties.removal_operation(self)
                        return triangular_primitive_properties.removal_operation()
                    end
                end
                
                return triangular_primitive_properties[property_identifier]
            end
        })
    end
end

getgenv().Drawing = drawing_interface
